cmake_minimum_required(VERSION 3.16)
project(gdc_resolve_encoder CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(PLUGIN_NAME gdc_resolve_encoder)

add_library(${PLUGIN_NAME} SHARED
    src/plugin.cpp
    src/ffmpeg_encoder.cpp
    src/license_check.cpp
    vendor/ed25519/verify.c
    vendor/ed25519/ge.c
    vendor/ed25519/sc.c
    vendor/ed25519/fe.c
    vendor/ed25519/sha512.c
    wrapper/plugin_api.cpp
    wrapper/host_api.cpp
)

target_include_directories(${PLUGIN_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/wrapper
    ${CMAKE_SOURCE_DIR}/vendor/ed25519
)

if (WIN32)
    # Windows CI has no pkg-config; FFMPEG_ROOT points at an extracted
    # "ffmpeg-release-full-shared" build (see .github/workflows/build.yml).
    if (NOT FFMPEG_ROOT)
        message(FATAL_ERROR "Set -DFFMPEG_ROOT=<path to extracted ffmpeg-release-full-shared> on Windows")
    endif()
    target_include_directories(${PLUGIN_NAME} PRIVATE "${FFMPEG_ROOT}/include")
    target_link_directories(${PLUGIN_NAME} PRIVATE "${FFMPEG_ROOT}/lib")
    target_link_libraries(${PLUGIN_NAME} PRIVATE avcodec avutil swscale swresample)
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(FFMPEG REQUIRED IMPORTED_TARGET
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
    target_link_libraries(${PLUGIN_NAME} PRIVATE "-framework VideoToolbox" "-framework CoreMedia" "-framework CoreVideo" "-framework IOKit" "-framework CoreFoundation")
    # Apple Silicon only — Intel Macs are no longer a build target.
    set_target_properties(${PLUGIN_NAME} PROPERTIES OSX_ARCHITECTURES "arm64")
endif()

if (UNIX AND NOT APPLE)
    target_compile_options(${PLUGIN_NAME} PRIVATE -fvisibility=hidden)
endif()
