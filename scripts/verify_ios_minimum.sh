#!/usr/bin/env bash
# scripts/verify_ios_minimum.sh
#
# Verifies iOS MinimumOSVersion consistency across project config and the
# built app bundle. Catches ITMS-90208-style mismatches before App Store upload.
#
# Usage:
#   ./scripts/verify_ios_minimum.sh                         # default build output
#   ./scripts/verify_ios_minimum.sh path/to/Runner.app
#   ./scripts/verify_ios_minimum.sh path/to/App.ipa
#   ./scripts/verify_ios_minimum.sh path/to/Runner.xcarchive
#   ./scripts/verify_ios_minimum.sh --sources-only          # config files only
#   ./scripts/verify_ios_minimum.sh --strict              # fail on any framework != app min

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Frameworks we patch to match the app minimum during the Xcode build.
MANAGED_FRAMEWORKS=("App" "tonic_wrapper")

ERRORS=0
WARNINGS=0
STRICT=false

err() {
    echo "ERROR: $*" >&2
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo "WARN:  $*" >&2
    WARNINGS=$((WARNINGS + 1))
}

info() {
    echo "  $*"
}

plist_minimum() {
    local plist="$1"
    if [[ ! -f "$plist" ]]; then
        echo "MISSING"
        return
    fi
    plutil -extract MinimumOSVersion raw "$plist" 2>/dev/null || echo "MISSING"
}

binary_minos() {
    local binary="$1"
    if [[ ! -f "$binary" ]]; then
        echo "MISSING"
        return
    fi
    vtool -show-build "$binary" 2>/dev/null | awk '/minos/{print $2; exit}'
}

framework_binary() {
    local fw_dir="$1"
    local name
    name="$(basename "$fw_dir" .framework)"
    if [[ -f "$fw_dir/$name" ]]; then
        echo "$fw_dir/$name"
        return
    fi
    local candidate
    candidate="$(find "$fw_dir" -maxdepth 1 -type f ! -name Info.plist -print -quit 2>/dev/null || true)"
    echo "${candidate:-MISSING}"
}

is_managed_framework() {
    local name="$1"
    local managed
    for managed in "${MANAGED_FRAMEWORKS[@]}"; do
        [[ "$name" == "$managed" ]] && return 0
    done
    return 1
}

version_gt() {
  # Returns 0 if $1 > $2 (semver-ish x.y or x.y.z)
  local IFS=.
  local -a a b
  read -r -a a <<<"$1"
  read -r -a b <<<"$2"
  local i
  for i in 0 1 2; do
    local av="${a[$i]:-0}"
    local bv="${b[$i]:-0}"
    if ((10#$av > 10#$bv)); then return 0; fi
    if ((10#$av < 10#$bv)); then return 1; fi
  done
  return 1
}

read_project_minimums() {
    local podfile="$PROJECT_ROOT/ios/Podfile"
    local app_fw_plist="$PROJECT_ROOT/ios/Flutter/AppFrameworkInfo.plist"
    local build_native="$PROJECT_ROOT/scripts/build_native.sh"
    local pbxproj="$PROJECT_ROOT/ios/Runner.xcodeproj/project.pbxproj"

    PODFILE_MIN=""
    if [[ -f "$podfile" ]]; then
        PODFILE_MIN="$(sed -n "s/.*platform :ios, '\([^']*\)'.*/\1/p" "$podfile" | head -1)"
    fi

    APP_FW_MIN="$(plist_minimum "$app_fw_plist")"

    BUILD_NATIVE_MIN=""
    if [[ -f "$build_native" ]]; then
        BUILD_NATIVE_MIN="$(sed -n 's/^IOS_MIN_VERSION="\([^"]*\)".*/\1/p' "$build_native" | head -1)"
    fi

    PBXPROJ_MINS=""
    if [[ -f "$pbxproj" ]]; then
        PBXPROJ_MINS="$(grep -o 'IPHONEOS_DEPLOYMENT_TARGET = [^;]*' "$pbxproj" | awk '{print $3}' | sort -u | tr '\n' ' ')"
    fi
}

check_source_files() {
    echo "=== Project configuration ==="
    read_project_minimums

    local -a found=()
    [[ -n "$PODFILE_MIN" ]] && found+=("Podfile:$PODFILE_MIN")
    [[ "$APP_FW_MIN" != "MISSING" && -n "$APP_FW_MIN" ]] && found+=("AppFrameworkInfo.plist:$APP_FW_MIN")
    [[ -n "$BUILD_NATIVE_MIN" ]] && found+=("build_native.sh:$BUILD_NATIVE_MIN")

    for entry in "${found[@]}"; do
        info "$entry"
    done

    if [[ -n "$PBXPROJ_MINS" ]]; then
        info "project.pbxproj deployment targets: $PBXPROJ_MINS"
    fi

    local expected=""
    for entry in "${found[@]}"; do
        local value="${entry#*:}"
        if [[ -z "$expected" ]]; then
            expected="$value"
        elif [[ "$value" != "$expected" ]]; then
            err "Project config mismatch: expected all sources to agree on $expected, found $entry"
        fi
    done

    if [[ -n "$PBXPROJ_MINS" ]]; then
        local pbx_min
        for pbx_min in $PBXPROJ_MINS; do
            if [[ -n "$expected" && "$pbx_min" != "$expected" ]]; then
                err "project.pbxproj has IPHONEOS_DEPLOYMENT_TARGET=$pbx_min, expected $expected"
            elif [[ -z "$expected" ]]; then
                expected="$pbx_min"
            fi
        done
        if [[ "$(echo "$PBXPROJ_MINS" | wc -w | tr -d ' ')" -gt 1 ]]; then
            err "project.pbxproj has multiple deployment targets: $PBXPROJ_MINS"
        fi
    fi

    if [[ -z "$expected" ]]; then
        err "Could not determine expected iOS minimum from project files"
        return 1
    fi

    echo "  => expected minimum: $expected"
    echo ""
    EXPECTED_MIN="$expected"
}

resolve_app_path() {
    local input="${1:-}"

    if [[ -n "$input" && "$input" != "--sources-only" && "$input" != "--strict" ]]; then
        case "$input" in
            *.ipa)
                local tmp_dir
                tmp_dir="$(mktemp -d)"
                trap 'rm -rf "$tmp_dir"' EXIT
                unzip -q "$input" -d "$tmp_dir"
                echo "$tmp_dir/Payload/Runner.app"
                return
                ;;
            *.xcarchive)
                echo "$input/Products/Applications/Runner.app"
                return
                ;;
            *)
                echo "$input"
                return
                ;;
        esac
    fi

    local -a candidates=(
        "$PROJECT_ROOT/build/ios/iphoneos/Runner.app"
        "$PROJECT_ROOT/build/ios/Release-iphoneos/Runner.app"
    )
    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -d "$candidate" ]]; then
            echo "$candidate"
            return
        fi
    done

    echo ""
}

check_app_bundle() {
    local app_path="$1"
    local expected="${2:-}"

    echo "=== App bundle: $app_path ==="

    if [[ ! -d "$app_path" ]]; then
        err "App bundle not found: $app_path"
        err "Build first: flutter build ios --release"
        return 1
    fi

    local app_plist="$app_path/Info.plist"
    local app_min
    app_min="$(plist_minimum "$app_plist")"

    if [[ "$app_min" == "MISSING" ]]; then
        err "Runner.app Info.plist is missing MinimumOSVersion"
    else
        info "Runner.app => $app_min"
    fi

    if [[ -z "$expected" ]]; then
        expected="$app_min"
    elif [[ "$app_min" != "MISSING" && "$app_min" != "$expected" ]]; then
        err "Runner.app MinimumOSVersion is $app_min, expected $expected"
    fi

    if [[ -z "$expected" || "$expected" == "MISSING" ]]; then
        err "No expected minimum version to compare against"
        return 1
    fi

    local frameworks_dir="$app_path/Frameworks"
    if [[ ! -d "$frameworks_dir" ]]; then
        warn "No Frameworks directory in app bundle"
        return 0
    fi

    echo ""
    echo "=== Embedded frameworks ==="

    local fw_dir fw_name plist_min binary binary_min
    for fw_dir in "$frameworks_dir"/*.framework; do
        [[ -d "$fw_dir" ]] || continue
        fw_name="$(basename "$fw_dir" .framework)"

        plist_min="$(plist_minimum "$fw_dir/Info.plist")"
        binary="$(framework_binary "$fw_dir")"
        binary_min="$(binary_minos "$binary")"

        info "$fw_name: plist=$plist_min, binary minos=${binary_min:-MISSING}"

        if [[ "$plist_min" == "MISSING" ]]; then
            if is_managed_framework "$fw_name"; then
                err "$fw_name.framework Info.plist is missing MinimumOSVersion"
            else
                warn "$fw_name.framework Info.plist is missing MinimumOSVersion"
            fi
        elif is_managed_framework "$fw_name" && [[ "$plist_min" != "$expected" ]]; then
            err "$fw_name.framework Info.plist is $plist_min, expected $expected"
        elif [[ "$STRICT" == true && "$plist_min" != "$expected" ]]; then
            err "$fw_name.framework Info.plist is $plist_min, expected $expected (--strict)"
        elif [[ "$plist_min" != "$expected" ]]; then
            warn "$fw_name.framework Info.plist is $plist_min (app is $expected; third-party frameworks are usually OK)"
        fi

        if [[ "$binary_min" == "MISSING" || -z "$binary_min" ]]; then
            if is_managed_framework "$fw_name"; then
                warn "$fw_name.framework: could not read binary minos"
            fi
            echo ""
            continue
        fi

        # ITMS-90208 root cause: framework plist claims older OS than binary requires.
        if [[ "$plist_min" != "MISSING" ]] && version_gt "$binary_min" "$plist_min"; then
            err "$fw_name.framework binary requires iOS $binary_min but Info.plist says $plist_min"
            if [[ "$fw_name" == "tonic_wrapper" ]]; then
                err "  => rebuild native libs: ./scripts/build_native.sh"
            fi
        fi

        if is_managed_framework "$fw_name" && [[ "$binary_min" != "$expected" && "$fw_name" == "tonic_wrapper" ]]; then
            err "$fw_name.framework binary minos is $binary_min, expected $expected"
            err "  => rebuild native libs: ./scripts/build_native.sh"
        fi

        echo ""
    done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

SOURCES_ONLY=false
INPUT_PATH=""

for arg in "$@"; do
    case "$arg" in
        --sources-only) SOURCES_ONLY=true ;;
        --strict) STRICT=true ;;
        *) INPUT_PATH="$arg" ;;
    esac
done

echo "=== iOS minimum version verification ==="
echo ""

check_source_files

if [[ "$SOURCES_ONLY" == true ]]; then
    if [[ "$ERRORS" -gt 0 ]]; then
        echo ""
        echo "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
        exit 1
    fi
    echo "PASSED: project configuration is consistent ($EXPECTED_MIN)"
    exit 0
fi

APP_PATH="$(resolve_app_path "$INPUT_PATH")"
if [[ -z "$APP_PATH" ]]; then
    err "No built Runner.app found"
    err "Run: flutter build ios --release"
    err "Or pass a path: ./scripts/verify_ios_minimum.sh path/to/Runner.app"
    echo ""
    echo "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
    exit 1
fi

check_app_bundle "$APP_PATH" "$EXPECTED_MIN"

echo "=== Summary ==="
if [[ "$ERRORS" -gt 0 ]]; then
    echo "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
    echo ""
    echo "Next steps:"
    echo "  ./scripts/build_native.sh        # if tonic_wrapper binary minos is wrong"
    echo "  flutter clean && flutter build ipa --release"
    echo "  ./scripts/verify_ios_minimum.sh  # re-check"
    exit 1
fi

if [[ "$WARNINGS" -gt 0 ]]; then
    echo "PASSED with $WARNINGS warning(s): no ITMS-90208 mismatches detected (app min $EXPECTED_MIN)"
else
    echo "PASSED: no ITMS-90208 mismatches detected (app min $EXPECTED_MIN)"
fi
