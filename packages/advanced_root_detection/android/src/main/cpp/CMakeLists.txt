cmake_minimum_required(VERSION 3.22.1)
project(shield)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Hardening flags
add_compile_options(
    -O2
    -fvisibility=hidden
    -fstack-protector-strong
    -D_FORTIFY_SOURCE=2
    -fno-exceptions
    -fno-rtti
)

add_library(shield SHARED
    jni_bridge.cpp
    anti_debug.cpp
    hook_detector.cpp
    integrity_check.cpp
    proc_scanner.cpp
    property_reader.cpp
    zygisk_detector.cpp
)

find_library(log-lib log)
find_library(android-lib android)

target_link_libraries(shield
    ${log-lib}
    ${android-lib}
)

# 16 KB page size alignment for Android 15+ / Google Play compliance (NDK r27+).
target_link_options(shield PRIVATE
    "-Wl,-z,max-page-size=16384"
)

# Strip symbols in release
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_link_options(shield PRIVATE -Wl,--strip-all)
endif()
