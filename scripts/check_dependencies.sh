#!/usr/bin/env bash
#
# check_dependencies.sh
#
# Checks shared library dependencies for:
#   - iOS xcframework binaries (via otool -L)
#   - Android .so binaries per-ABI (via readelf -d | grep NEEDED)
#
# Usage:
#   ./check_dependencies.sh
#
# Optional overrides (env vars):
#   IOS_XCFRAMEWORK   path to the .xcframework (default: native/libs/ios/libtonic_wrapper.xcframework)
#   ANDROID_LIBS_DIR  path to the android libs dir (default: native/libs/android)
#   ANDROID_SO_NAME   name of the .so file (default: libtonic_wrapper.so)

set -uo pipefail

IOS_XCFRAMEWORK="${IOS_XCFRAMEWORK:-native/libs/ios/libtonic_wrapper.xcframework}"
ANDROID_LIBS_DIR="${ANDROID_LIBS_DIR:-native/libs/android}"
ANDROID_SO_NAME="${ANDROID_SO_NAME:-libtonic_wrapper.so}"

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

section() {
  echo
  echo -e "${BOLD}==============================================${RESET}"
  echo -e "${BOLD}$1${RESET}"
  echo -e "${BOLD}==============================================${RESET}"
}

warn() {
  echo -e "${YELLOW}warning:${RESET} $1"
}

err() {
  echo -e "${RED}error:${RESET} $1"
}

# ---------------------------------------------------------------------------
# iOS: otool -L on every framework binary found inside the xcframework
# ---------------------------------------------------------------------------
check_ios() {
  section "iOS (xcframework): ${IOS_XCFRAMEWORK}"

  if ! command -v otool >/dev/null 2>&1; then
    err "otool not found. This step needs to run on macOS with Xcode command line tools installed."
    return 1
  fi

  if [ ! -d "${IOS_XCFRAMEWORK}" ]; then
    err "xcframework not found at ${IOS_XCFRAMEWORK}"
    return 1
  fi

  # Find framework binaries: <slice>/<name>.framework/<name> (no extension, matches dir base name)
  local found=0
  while IFS= read -r -d '' framework_dir; do
    local base
    base="$(basename "${framework_dir}" .framework)"
    local binary="${framework_dir}/${base}"

    if [ -f "${binary}" ]; then
      found=1
      local slice
      slice="$(basename "$(dirname "${framework_dir}")")"
      echo
      echo -e "${GREEN}--- slice: ${slice} (${binary}) ---${RESET}"
      otool -L "${binary}"
    else
      warn "expected binary not found at ${binary}"
    fi
  done < <(find "${IOS_XCFRAMEWORK}" -type d -name "*.framework" -print0)

  if [ "${found}" -eq 0 ]; then
    warn "no framework binaries found under ${IOS_XCFRAMEWORK}"
  fi
}

# ---------------------------------------------------------------------------
# Android: readelf -d | grep NEEDED for each ABI directory
# ---------------------------------------------------------------------------
find_readelf() {
  # Preference order: explicit override, system readelf (Linux), Homebrew's
  # greadelf (macOS), then fall back to scanning known Android SDK locations
  # for the NDK's llvm-readelf. No machine-specific paths are assumed.
  if [ -n "${READELF_BIN:-}" ] && command -v "${READELF_BIN}" >/dev/null 2>&1; then
    command -v "${READELF_BIN}"
    return 0
  fi

  if command -v readelf >/dev/null 2>&1; then
    command -v readelf
    return 0
  fi

  if command -v greadelf >/dev/null 2>&1; then
    command -v greadelf
    return 0
  fi

  # Common places an Android SDK/NDK might live, in rough order of likelihood.
  # $ANDROID_HOME / $ANDROID_SDK_ROOT take priority when set; the rest are
  # standard install locations for Android Studio, sdkmanager, and Homebrew.
  local candidate_roots=()
  [ -n "${ANDROID_HOME:-}" ] && candidate_roots+=("${ANDROID_HOME}")
  [ -n "${ANDROID_SDK_ROOT:-}" ] && candidate_roots+=("${ANDROID_SDK_ROOT}")
  candidate_roots+=(
    "${HOME}/Library/Android/sdk"
    "${HOME}/Android/Sdk"
    "/usr/local/share/android-sdk"
    "/opt/homebrew/share/android-sdk"
  )

  local root ndk_readelf
  for root in "${candidate_roots[@]}"; do
    [ -d "${root}/ndk" ] || continue
    # Plain reverse lexicographic sort (portable across BSD/macOS sort and
    # GNU sort — unlike `sort -V`, which macOS's built-in sort lacks).
    # NDK version directories are zero-padded consistently enough that this
    # orders newest-first correctly.
    ndk_readelf="$(find "${root}/ndk" -mindepth 2 -name "llvm-readelf" 2>/dev/null | sort -r | head -n1)"
    if [ -n "${ndk_readelf}" ] && [ ! -x "${ndk_readelf}" ]; then
      ndk_readelf=""
    fi
    if [ -n "${ndk_readelf}" ]; then
      echo "${ndk_readelf}"
      return 0
    fi
  done

  echo "  (checked NDK install locations: ${candidate_roots[*]})" >&2
  return 1
}

check_android() {
  section "Android (.so): ${ANDROID_LIBS_DIR}"

  local READELF
  READELF="$(find_readelf)"
  if [ -z "${READELF}" ]; then
    err "no readelf-compatible tool found. Install one of:"
    err "  brew install binutils          (provides 'greadelf')"
    err "  or use the NDK's llvm-readelf (set ANDROID_HOME, or pass READELF_BIN=/path/to/llvm-readelf)"
    return 1
  fi
  echo "using: ${READELF}"

  if [ ! -d "${ANDROID_LIBS_DIR}" ]; then
    err "android libs dir not found at ${ANDROID_LIBS_DIR}"
    return 1
  fi

  local found=0
  for abi_dir in "${ANDROID_LIBS_DIR}"/*/; do
    [ -d "${abi_dir}" ] || continue
    local abi
    abi="$(basename "${abi_dir}")"
    local so_path="${abi_dir}${ANDROID_SO_NAME}"

    echo
    echo -e "${GREEN}--- ABI: ${abi} (${so_path}) ---${RESET}"

    if [ -f "${so_path}" ]; then
      found=1
      "${READELF}" -d "${so_path}" | grep NEEDED || echo "  (no NEEDED entries found)"
    else
      warn "${so_path} not found, skipping"
    fi
  done

  if [ "${found}" -eq 0 ]; then
    warn "no .so files named ${ANDROID_SO_NAME} found under ${ANDROID_LIBS_DIR}"
  fi
}

main() {
  check_ios
  ios_status=$?
  check_android
  android_status=$?

  echo
  section "Summary"
  [ "${ios_status}" -eq 0 ] && echo -e "iOS:     ${GREEN}OK${RESET}" || echo -e "iOS:     ${RED}FAILED${RESET}"
  [ "${android_status}" -eq 0 ] && echo -e "Android: ${GREEN}OK${RESET}" || echo -e "Android: ${RED}FAILED${RESET}"

  if [ "${ios_status}" -ne 0 ] || [ "${android_status}" -ne 0 ]; then
    exit 1
  fi
}

main "$@"