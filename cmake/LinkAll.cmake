# すでに opencv_part.lib と vala_part.lib がある前提でリンクだけする

add_executable(img_viewer)

target_link_libraries(img_viewer
    PRIVATE
    ${CMAKE_SOURCE_DIR}/build_opencv/libopencv_part.a
    ${CMAKE_SOURCE_DIR}/build_vala/libvala_part.a
)

set_target_properties(img_viewer PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

message(STATUS "✅ Linked final executable -> img_viewer.exe")
