cmake_minimum_required(VERSION 3.16)
project(x264_encoder_plugin_reference CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Unmodified official Blackmagic SDK example, built as-is, to test whether
# "Failed to add video track" also happens with the reference implementation
# itself — if it does, the issue isn't in GDC Resolve Encoder's code at all.
find_package(PkgConfig REQUIRED)
pkg_check_modules(X264 REQUIRED IMPORTED_TARGET x264)

add_library(x264_encoder_plugin_reference SHARED
    plugin.cpp
    x264_encoder.cpp
    dummy_container.cpp
    audio_encoder.cpp
    wrapper/plugin_api.cpp
    wrapper/host_api.cpp
)

target_include_directories(x264_encoder_plugin_reference PRIVATE
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/../include
    ${CMAKE_SOURCE_DIR}/wrapper
)

target_link_libraries(x264_encoder_plugin_reference PRIVATE PkgConfig::X264)

set_target_properties(x264_encoder_plugin_reference PROPERTIES
    PREFIX ""
    OUTPUT_NAME "x264_encoder_plugin_reference"
    SUFFIX ".dvcp"
)

if (APPLE)
    set_target_properties(x264_encoder_plugin_reference PROPERTIES OSX_ARCHITECTURES "arm64")
endif()
