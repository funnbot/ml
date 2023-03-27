cmake_minimum_required(VERSION 3.16)

project(ml CXX)

include("${CMAKE_CURRENT_SOURCE_DIR}/external/fun-cmake/platform.cmake")

option(BUILD_SHARED_LIBS OFF)

add_subdirectory(external/Orochi)

add_executable(ml src/main.cpp)
target_link_libraries(ml PRIVATE Orochi)
target_compile_features(ml PRIVATE cxx_std_20)
target_include_directories(ml PRIVATE "${CMAKE_BINARY_DIR}/baked")

fun_target_strict_conformance(ml)
fun_target_enable_diagnostics(ml)

install(TARGETS ml EXPORT ml RUNTIME)

add_subdirectory(src/cuda)