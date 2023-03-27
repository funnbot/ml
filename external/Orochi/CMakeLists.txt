cmake_minimum_required(VERSION 3.16)
project(YamatanoOrochi LANGUAGES CXX)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(ORO_STANDALONE TRUE)
else()
    set(ORO_STANDALONE FALSE)
endif()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_DEBUG_POSTFIX "d")

if(WIN32)
    # links with system libraries that don't have static options, so must link with dynamic crt
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    set(CMAKE_STATIC_LIBRARY_SUFFIX ".static.lib")
endif()

add_library(Orochi)
target_compile_features(Orochi PUBLIC cxx_std_17)

target_sources(Orochi PRIVATE
    Orochi/Orochi.cpp
    Orochi/OrochiUtils.cpp

    contrib/cuew/src/cuew.cpp
    contrib/hipew/src/hipew.cpp)

target_include_directories(Orochi PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:Orochi>)

# Platform-specific settings
if (WIN32)
    target_compile_definitions(Orochi PUBLIC _CRT_SECURE_NO_WARNINGS)
elseif(UNIX AND NOT APPLE)
    link_libraries(dl)
endif()

if (MSVC)
    target_link_libraries(Orochi PUBLIC version)
endif()

if(WIN32)
    install(DIRECTORY contrib/bin/win64/ TYPE BIN)
endif()

if(ORO_STANDALONE)
    install(TARGETS Orochi EXPORT Orochi
        ARCHIVE LIBRARY OPTIONAL RUNTIME OPTIONAL PUBLIC_HEADER)
    install(EXPORT Orochi NAMESPACE Orochi
        DESTINATION share/Orochi)
endif()