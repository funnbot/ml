set(CUDA_SOURCES test.cu)

set(BAKED_DIR "${CMAKE_BINARY_DIR}/baked")
file(MAKE_DIRECTORY "${BAKED_DIR}")
foreach(cuda_src IN LISTS CUDA_SOURCES)
    get_filename_component(cuda_src_name "${cuda_src}" NAME_WE)

    MESSAGE("Generating ${cuda_src_name}")
    
    execute_process(COMMAND "python"
        "${CMAKE_CURRENT_SOURCE_DIR}/../../external/Orochi/tools/genArgs.py"
        "${cuda_src}"
        OUTPUT_FILE "${BAKED_DIR}/${cuda_src_name}.args.hpp"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
    execute_process(COMMAND "python"
        "${CMAKE_CURRENT_SOURCE_DIR}/../../external/Orochi/tools/stringify.py"
        "${cuda_src}"
        OUTPUT_FILE "${BAKED_DIR}/${cuda_src_name}.hpp"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
endforeach()
