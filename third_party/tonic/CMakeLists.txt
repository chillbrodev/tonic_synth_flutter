cmake_minimum_required(VERSION 3.18)
project(tonic_wrapper CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---------------------------------------------------------------------------
# Tonic sources
#
# Tonic is NOT header-only — each class has a .cpp translation unit.
# We compile them all into the same shared library as the wrapper so the
# Flutter package only needs to bundle one .so.
#
# AudioFileUtils is guarded by #ifdef __APPLE__ so it compiles to nothing
# on Android — safe to include unconditionally.
# ---------------------------------------------------------------------------

file(GLOB TONIC_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/src/Tonic/*.cpp"
)

add_library(tonic_wrapper SHARED
    tonic_wrapper.cpp
    ${TONIC_SOURCES}
)

# ---------------------------------------------------------------------------
# Include paths
# ---------------------------------------------------------------------------

target_include_directories(tonic_wrapper PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"            # tonic_wrapper.h
    "${CMAKE_CURRENT_SOURCE_DIR}/src"        # for #include "Tonic/Foo.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/Tonic"  # for Tonic-internal cross-includes
)

# ---------------------------------------------------------------------------
# Compiler flags
# ---------------------------------------------------------------------------

target_compile_options(tonic_wrapper PRIVATE
    -O2
    -ffast-math
    # No -fvisibility=hidden here — we rely on the linker version script
    # exclusively to control the export surface. Mixing both causes the
    # version script glob to have nothing to match against.
)

# NEON for armeabi-v7a — NDK sets __ARM_NEON automatically for arm64,
# but armeabi-v7a needs an explicit opt-in.
if(ANDROID AND ANDROID_ABI STREQUAL "armeabi-v7a")
    target_compile_options(tonic_wrapper PRIVATE -mfpu=neon)
endif()

# ---------------------------------------------------------------------------
# Linker flags
#
# Version script: whitelist only tonic_* symbols for export.
# Everything else (Tonic C++ internals, STL symbols) stays local.
# ---------------------------------------------------------------------------

set(VERSION_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/tonic_wrapper.version")

target_link_options(tonic_wrapper PRIVATE
    -Wl,--version-script=${VERSION_SCRIPT}
    -Wl,--no-undefined   # catch missing symbols at link time, not at runtime
)

# Android-specific
if(ANDROID)
    target_link_libraries(tonic_wrapper PRIVATE log)
endif()

# ---------------------------------------------------------------------------
# Install — build_native.sh uses cmake --build --target install
# to copy the .so directly into native/libs/android/<ABI>/
# ---------------------------------------------------------------------------

install(TARGETS tonic_wrapper
    LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}"
)