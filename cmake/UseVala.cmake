# -------------------------------------------
# Minimal UseVala.cmake
# Provides the vala_precompile() macro
# Compiles ALL .vala at once (single valac invocation) to generate C sources.
# -------------------------------------------
macro(vala_precompile output_var)
    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs SOURCES PACKAGES VAPIS VAPIDIRS OPTIONS)
    cmake_parse_arguments(VALA "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT VALA_TARGET)
        message(FATAL_ERROR "vala_precompile() requires TARGET argument")
    endif()
    if(NOT VALA_SOURCES)
        message(FATAL_ERROR "vala_precompile() requires SOURCES")
    endif()

    # Compute output C files for each Vala source
    set(gen_c_files)
    foreach(src ${VALA_SOURCES})
        get_filename_component(src_name ${src} NAME_WE)
        list(APPEND gen_c_files "${CMAKE_CURRENT_BINARY_DIR}/${src_name}.c")
    endforeach()

    # Build --pkg arguments
    set(PKG_ARGS)
    foreach(pkg ${VALA_PACKAGES})
        list(APPEND PKG_ARGS --pkg ${pkg})
    endforeach()

    # Build --vapidir arguments
    set(VAPIDIR_ARGS)
    foreach(vd ${VALA_VAPIDIRS})
        list(APPEND VAPIDIR_ARGS --vapidir ${vd})
    endforeach()

    # Run a single valac to generate all C sources
    add_custom_command(
        OUTPUT ${gen_c_files}
        COMMAND ${VALA_EXECUTABLE}
        ARGS -C ${VALA_SOURCES} ${VALA_VAPIS}
             ${PKG_ARGS} ${VAPIDIR_ARGS} ${VALA_OPTIONS}
        DEPENDS ${VALA_SOURCES} ${VALA_VAPIS}
        COMMENT "Generating C from Vala sources for target ${VALA_TARGET}"
        VERBATIM
    )

    set(${output_var} ${gen_c_files})
endmacro()
