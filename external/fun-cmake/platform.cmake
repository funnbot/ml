include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.16)

# adds platform compiler definitions to target
# os one of: <prefix>_OS_WINDOWS, _MACOS, _LINUX, _UNKNOWN
# compiler one of: <prefix>_COMP_MSVC, _CLANG, _GCC, _UNKNOWN
function(fun_target_platform_definitions prefix target access_spec)
    if(WIN32)
        set(os_name "WINDOWS")
    elseif(APPLE)
        set(os_name "MACOS")
    elseif(UNIX)
        set(os_name "LINUX")
    else()
        set(os_name "UNKNOWN")
    endif()

    if(MSVC)
        set(comp_name "MSVC")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(comp_name "CLANG")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        set(comp_name "GCC")
    else()
        set(comp_name "UNKNOWN")
    endif()

    target_compile_definitions(${target} ${access_spec}
        ${prefix}_OS_${os_name}
        ${prefix}_COMP_${comp_name}
    )
endfunction()

# Set the CRT linkage on windows, by setting MSVC_RUNTIME_LIBRARY property
# use STATIC (/MT) or DYNAMIC (/MD)
function(fun_target_crt_linkage target)
    cmake_parse_arguments(PARSE_ARGV 1 _arg "STATIC;DYNAMIC" "" "")

    if(NOT target)
        message(FATAL_ERROR "argument target required")
    endif()

    if(_arg_DYNAMIC)
        set_target_properties(${target} PROPERTIES MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    elseif(_arg_STATIC)
        set_target_properties(${target} PROPERTIES MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        message(FATAL_ERROR "argument STATIC or DYNAMIC required")
    endif()
endfunction()

# Create debug symbols for release builds, msvc will generate a pdb,
# while gcc-like will have embedded symbols.
function(fun_exe_debug_symbols target)
    if(MSVC)
        # Generates debug symbols in a PDB
        target_compile_options(${target} PRIVATE
            "$<$<CONFIG:Release>:/Zi>")

        # enable debug and re-enable optimizations that it disables
        target_link_options(${target} PRIVATE
            "$<$<CONFIG:Release>:/DEBUG>"
            "$<$<CONFIG:Release>:/OPT:REF>"
            "$<$<CONFIG:Release>:/OPT:ICF>")

        # Set file name and location
        set_target_properties(${target} PROPERTIES
            COMPILE_PDB_NAME "${target}"
            COMPILE_PDB_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    else()
        target_compile_options("${target}" PRIVATE
            $<$<CONFIG:Release>:-g>)
    endif()
endfunction()

# sets pedantic-errors in gcc-like and permissive- in msvc
function(fun_target_strict_conformance target)
    if(MSVC)
        target_compile_options(${target} PRIVATE

            # all source files are utf8
            /utf-8

            # make msvc slightly more conformant to the standard
            /permissive-
            /Zc:inline
            /Zc:externConstexpr
            /Zc:preprocessor
            /Zc:throwingNew
        )
    else()
        target_compile_options(${target} PRIVATE

            # errors on non conforming code
            -pedantic-errors
        )
    endif()
endfunction()

# enable all diagnostics
function(fun_target_enable_diagnostics target)
    if(MSVC)
        target_compile_options(${target} PRIVATE

            # hide warnings from system includes
            /external:W0
            /external:anglebrackets # any include <> is external

            # enable diagnostics
            /W4

            # enable column numbers in diagnostics
            /diagnostics:column

            # various compiler and runtime checks
            /sdl

            # disable errors from using deprecated functions (set by /sdl)
            /wd4996
        )
    else()
        target_compile_options(${target} PRIVATE

            # enable diagnostics
            -Wall
            -Wextra
        )
    endif()
endfunction()

# enable extra diagnostics from analyzer, cpu intensive
function(fun_target_enable_analyzer target)
    if(MSVC)
        target_compile_options(${target} PRIVATE

            # enable analyzer
            /analyze
            /analyze:autolog- # disable log files
            /analyze:external-
        )
    else()
        target_compile_options(${target} PRIVATE

            # enable analyzer
            -fanalyzer
        )
    endif()
endfunction()

# disable all diagnostics when compiling target
function(fun_target_disable_diagnostics target)
    if(MSVC)
        target_compile_options(${target} PRIVATE
            /W0
        )
    else()
        target_compile_options(${target} PRIVATE
            -w
        )
    endif()
endfunction()

# enable address sanitizer
function(fun_target_enable_asan target)
    if(MSVC)
        target_compile_options(${target} PRIVATE
            /fsanitize=address
        )
        target_compile_definitions(${target} PRIVATE
            _DISABLE_VECTOR_ANNOTATION
        )
    else()
        target_compile_options(${target} PRIVATE
            -fsanitize=address
            -fsanitize=leak
            -fsanitize=undefined
        )
        target_link_options(${target} PRIVATE
            -fsanitize=address
            -fsanitize=leak
            -fsanitize=undefined
        )
    endif()
endfunction()
