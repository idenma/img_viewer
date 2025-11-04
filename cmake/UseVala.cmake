# -------------------------------------------
# Minimal UseVala.cmake
# Provides the vala_precompile() macro
# -------------------------------------------
macro(vala_precompile output_var)
    set(options CUSTOM_VAPIS)
    set(oneValueArgs TARGET)
    set(multiValueArgs SOURCES PACKAGES VAPIS OPTIONS)
    cmake_parse_arguments(VALA "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT VALA_TARGET)
        message(FATAL_ERROR "vala_precompile() requires TARGET argument")
    endif()

    set(${output_var})
    foreach(src ${VALA_SOURCES})
        get_filename_component(src_name ${src} NAME_WE)
        set(out "${CMAKE_CURRENT_BINARY_DIR}/${src_name}.c")
        add_custom_command(
            OUTPUT ${out}
            COMMAND ${VALA_EXECUTABLE}
            ARGS -C ${src} -o ${out}
                 ${VALA_OPTIONS}
                 ${VALA_PACKAGES}
                 ${VALA_VAPIS}
            DEPENDS ${src}
            COMMENT "Compiling Vala source ${src}"
            VERBATIM
        )
        list(APPEND ${output_var} ${out})
    endforeach()
endmacro()
