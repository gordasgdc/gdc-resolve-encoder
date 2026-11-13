cmake_minimum_required(VERSION 3.16)
# Minimum macOS declared by the build (must be set before project()). 26.0 is
# the floor of the bundled FFmpeg/x264/x265/... libraries (see the minos check
# in build_installer.sh). Override with -DCMAKE_OSX_DEPLOYMENT_TARGET=...
if(APPLE AND NOT DEFINED CMAKE_OSX_DEPLOYMENT_TARGET)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "26.0" CACHE STRING "Minimum macOS version")
endif()
project(gdc_resolve_encoder VERSION 1.8.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(PLUGIN_NAME gdc_resolve_encoder)

add_library(${PLUGIN_NAME} SHARED
    src/plugin.cpp
    src/ffmpeg_encoder.cpp
    src/gdc_container.cpp
    src/gdc_mux.cpp
    wrapper/plugin_api.cpp
    wrapper/host_api.cpp
)

target_include_directories(${PLUGIN_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/wrapper
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE GDC_ENCODER_VERSION="${PROJECT_VERSION}")

if (WIN32)
    # Windows CI has no pkg-config; FFMPEG_ROOT points at an extracted
    # "ffmpeg-release-full-shared" build (see .github/workflows/build.yml).
    if (NOT FFMPEG_ROOT)
        message(FATAL_ERROR "Set -DFFMPEG_ROOT=<path to extracted ffmpeg-release-full-shared> on Windows")
    endif()
    target_include_directories(${PLUGIN_NAME} PRIVATE "${FFMPEG_ROOT}/include")
    target_link_directories(${PLUGIN_NAME} PRIVATE "${FFMPEG_ROOT}/lib")
    target_link_libraries(${PLUGIN_NAME} PRIVATE avformat avcodec avutil swscale swresample)
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(FFMPEG REQUIRED IMPORTED_TARGET
        libavformat
        libavcodec
        libavutil
        libswscale
    )
    target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::FFMPEG)
endif()

set_target_properties(${PLUGIN_NAME} PROPERTIES
    PREFIX ""
    SUFFIX ".dvcp"
)

if (APPLE)
    target_link_libraries(${PLUGIN_NAME} PRIVATE "-framework VideoToolbox" "-framework CoreMedia" "-framework CoreVideo" "-framework CoreFoundation")
    # Apple Silicon only — Intel Macs are no longer a build target.
    set_target_properties(${PLUGIN_NAME} PROPERTIES OSX_ARCHITECTURES "arm64")
endif()

if (UNIX AND NOT APPLE)
    target_compile_options(${PLUGIN_NAME} PRIVATE -fvisibility=hidden)
endif()

# Regression harness for the GDC containers (no Resolve needed):
#   cmake --build <dir> --target mux_roundtrip && tests/run_mux_tests.sh <dir>/mux_roundtrip <scratch-dir>
if (NOT WIN32)
    add_executable(mux_roundtrip EXCLUDE_FROM_ALL tests/mux_roundtrip.cpp src/gdc_mux.cpp)
    target_include_directories(mux_roundtrip PRIVATE ${CMAKE_SOURCE_DIR})
    target_link_libraries(mux_roundtrip PRIVATE PkgConfig::FFMPEG)
endif()

# Pixel-conversion unit test (no Resolve, no FFmpeg):
#   cmake --build <dir> --target pixconv_test && <dir>/pixconv_test
add_executable(pixconv_test EXCLUDE_FROM_ALL tests/pixconv_test.cpp)
target_include_directories(pixconv_test PRIVATE ${CMAKE_SOURCE_DIR})
