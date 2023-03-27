include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.16)

include("${CMAKE_CURRENT_LIST_DIR}/common.cmake")

# clone a local vcpkg install if user doesn't already have
# must be called before project()
# sets the toolchain file to vcpkg.cmake
# recommended to add /vcpkg to .gitignore
# set VCPKG_ROOT or ENV{VCPKG_ROOT} to use an alternate vcpkg install location
function(fun_bootstrap_vcpkg)
    fun_parse_arguments(0 _arg
        "NO_SYSTEM;CLEAN_BUILD;CLEAN_DOWNLOADS"
        "VERSION_TAG;TRIPLET"
        "OVERLAY_PORTS;OVERLAY_TRIPLETS"
        "TRIPLET")

    if(DEFINED CMAKE_PROJECT_NAME AND NOT DEFINED VCPKG_ROOT)
        if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
            message(FATAL_ERROR "fun_boostrap_vcpkg() must be called before project()")
        else()
            message(WARNING "fun_boostrap_vcpkg() may not work with add_subdirectory()")
        endif()
    endif()

    # custom toolchain and first run
    if(DEFINED CMAKE_TOOLCHAIN_FILE AND NOT DEFINED VCPKG_ROOT)
        message(STATUS "using custom toolchain, include vcpkg to build dependencies.")
        return()
    endif()

    set(VCPKG_TARGET_TRIPLET "${_arg_TRIPLET}" CACHE STRING "")

    set(install_options "--clean-packages-after-build")

    if(DEFINED _arg_VERSION_TAG)
        set(version_tag_opt "--branch ${_arg_VERSION_TAG}")

        # if checking out specific commit, then stability is important
        list(APPEND install_options "--x-abi-tools-use-exact-versions")
    else()
        set(version_tag_opt "")
    endif()

    if(_arg_CLEAN_DOWNLOADS)
        list(APPEND install_options "--clean-downloads-after-build")
    endif()

    if(_arg_CLEAN_BUILD)
        list(APPEND install_options "--clean-buildtrees-after-build")
    endif()

    set(VCPKG_INSTALL_OPTIONS ${install_options} CACHE STRING "")

    if(DEFINED _arg_OVERLAY_PORTS)
        set(VCPKG_OVERLAY_PORTS ${_arg_OVERLAY_PORTS} CACHE STRING "")
    endif()

    if(DEFINED _arg_OVERLAY_TRIPLETS)
        set(VCPKG_OVERLAY_TRIPLETS ${_arg_OVERLAY_TRIPLETS} CACHE STRING "")
    endif()

    if(DEFINED ENV{VCPKG_ROOT} AND NOT _arg_NO_SYSTEM)
        set(vcpkg_default_root "$ENV{VCPKG_ROOT}")
    else()
        set(vcpkg_default_root "${CMAKE_SOURCE_DIR}/vcpkg")
    endif()

    set(VCPKG_ROOT "${vcpkg_default_root}" CACHE PATH "vcpkg root directory")
    message(STATUS "vcpkg root: ${VCPKG_ROOT}")

    if(WIN32)
        set(vcpkg_cmd "${VCPKG_ROOT}/${vcpkg_cmd}")
        set(vcpkg_bootstrap_cmd "${VCPKG_ROOT}/bootstrap-vcpkg.bat")
    else()
        set(vcpkg_cmd "${VCPKG_ROOT}/${vcpkg_cmd}")
        set(vcpkg_bootstrap_cmd "${VCPKG_ROOT}/bootstrap-vcpkg.sh")
    endif()

    find_package(Git REQUIRED)

    if(NOT EXISTS "${vcpkg_bootstrap_cmd}")
        execute_process(COMMAND "${GIT_EXECUTABLE}" clone --filter=tree:0 ${version_tag_opt}
            "https://github.com/microsoft/vcpkg.git" "${VCPKG_ROOT}")

        if(NOT EXISTS "${vcpkg_bootstrap_cmd}")
            message(FATAL_ERROR "failed to clone vcpkg")
        endif()
    elseif(DEFINED _arg_VERSION_TAG)
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" checkout "${_arg_VERSION_TAG}"
            WORKING_DIRECTORY "${VCPKG_ROOT}")
    elseif(_arg_VERSION_TAG STREQUAL "master")
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" checkout master
            COMMAND "${GIT_EXECUTABLE}" pull
            WORKING_DIRECTORY "${VCPKG_ROOT}")
    endif()

    if(NOT EXISTS "${vcpkg_cmd}")
        execute_process(COMMAND "${vcpkg_bootstrap_cmd}" -disableMetrics
            WORKING_DIRECTORY "${VCPKG_ROOT}")

        if(NOT EXISTS "${vcpkg_cmd}")
            message(FATAL_ERROR "failed to bootstrap vcpkg")
        endif()
    endif()

    if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
        set(CMAKE_TOOLCHAIN_FILE "${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
    endif()
endfunction()

# guess a vcpkg triplet for this platform
function(fun_guess_vcpkg_triplet out_triplet)
    if(NOT DEFINED BUILD_SHARED_LIBS OR "x${BUILD_SHARED_LIBS}x" STREQUAL "xx")
        message(FATAL_ERROR "BUILD_SHARED_LIBS must be set")
    endif()

    set(target_arch "x64")

    if(WIN32)
        set(triplet "${target_arch}-windows")

        if(NOT BUILD_SHARED_LIBS)
            set(triplet "${triplet}-static")
        endif()
    elseif(UNIX)
        if(APPLE)
            set(triplet "${target_arch}-osx")
        else()
            set(triplet "${target_arch}-linux")
        endif()

        if(BUILD_SHARED_LIBS)
            set(triplet "${triplet}-dynamic")
        endif()
    endif()

    set(${out_triplet} "${triplet}" PARENT_SCOPE)
endfunction()

function(fun_clean_vcpkg_buildtrees_keep_sources)
    if(NOT DEFINED CMAKE_PROJECT_NAME)
        message(FATAL_ERROR "must be called after project()")
    endif()

    if(NOT DEFINED VCPKG_ROOT)
        message(FATAL_ERROR "fun_boostrap_vcpkg should have been called already")
    endif()

    get_filename_component(vcpkg_dir "${VCPKG_ROOT}"
        ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

    if(NOT IS_DIRECTORY "${vcpkg_dir}")
        message(FATAL_ERROR "can't find vcpkg root")
    endif()

    file(GLOB all_packages LIST_DIRECTORIES true "${vcpkg_dir}/buildtrees/*")

    foreach(package IN LISTS all_packages)
        if(NOT IS_DIRECTORY package)
            continue()
        endif()

        if(NOT(package MATCHES "-((dbg)|(rel))$"))
            continue()
        endif()

        file(GLOB subdirs LIST_DIRECTORIES true "${package}/*")

        foreach(dir IN LISTS subdirs)
            if(NOT IS_DIRECTORY dir)
                continue()
            endif()

            if(NOT(dir MATCHES "/src$"))
                continue()
            endif()

            message(STATUS "removing '${dir}'")
            file(REMOVE_RECURSE "${dir}")
        endforeach()
    endforeach()
endfunction()