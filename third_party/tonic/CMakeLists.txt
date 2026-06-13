cmake_minimum_required(VERSION 3.18)
project(tonic_wrapper CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---------------------------------------------------------------------------
# Tonic sources
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
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/Tonic"
)

# ---------------------------------------------------------------------------
# Compiler flags
# ---------------------------------------------------------------------------

target_compile_options(tonic_wrapper PRIVATE
    -O2
    -ffast-math
)

# armeabi-v7a NEON opt-in
if(ANDROID AND ANDROID_ABI STREQUAL "armeabi-v7a")
    target_compile_options(tonic_wrapper PRIVATE -mfpu=neon)
endif()

# ---------------------------------------------------------------------------
# Linker flags — platform-specific symbol visibility
# ---------------------------------------------------------------------------

if(ANDROID)
    # GNU/LLVM lld: version script whitelists tonic_* only
    set(VERSION_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/tonic_wrapper.version")
    target_link_options(tonic_wrapper PRIVATE
        -Wl,--version-script=${VERSION_SCRIPT}
        -Wl,--no-undefined
    )
    target_link_libraries(tonic_wrapper PRIVATE log)

elseif(APPLE)
    # Apple ld: exported_symbols_list whitelists tonic_* only
    # On iOS the STL is provided by the OS — no bundling needed.
    set(EXPORTED_SYMBOLS "${CMAKE_CURRENT_SOURCE_DIR}/tonic_wrapper_ios.exp")
    target_link_options(tonic_wrapper PRIVATE
        -Wl,-exported_symbols_list,${EXPORTED_SYMBOLS}
    )
    # AudioToolbox is used by AudioFileUtils on Apple platforms
    target_link_libraries(tonic_wrapper PRIVATE
        "-framework Accelerate"
        "-framework AudioToolbox"
        "-framework Foundation"
    )
    # Ensure .dylib install name is correct for embedding
    set_target_properties(tonic_wrapper PROPERTIES
        INSTALL_NAME_DIR "@rpath"
        BUILD_WITH_INSTALL_NAME_DIR YES
    )
endif()

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

install(TARGETS tonic_wrapper
    LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}"
)