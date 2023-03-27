cmake_minimum_required(VERSION 3.16)

project(ml CXX)

option(BUILD_SHARED_LIBS OFF)

add_subdirectory(external/Orochi)

add_executable(ml src/main.cpp)
target_link_libraries(ml PRIVATE Orochi)

target_compile_features(ml PRIVATE cxx_std_20)
