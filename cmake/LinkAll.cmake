# すでに targets: opencv_part, vala_part が存在する前提でリンクのみ行う
# NOTE: 実行ファイルのソースはダミーCを与え、実体はライブラリ側（Vala生成物）に含まれる main() を使用

# ダミーのCソース（空コンパイル単位）
set(DUMMY_C "${CMAKE_SOURCE_DIR}/src/vala/dummy.c")
if(NOT EXISTS ${DUMMY_C})
    file(WRITE ${DUMMY_C} "/* dummy compilation unit for linking Vala objects */\n")
endif()

add_executable(img_viewer ${DUMMY_C})

set(IMG_VIEWER_LIBS vala_part)
if (ENABLE_OPENCV_FACE)
    list(APPEND IMG_VIEWER_LIBS opencv_part ${OPENCV_LIBRARIES})
endif()

target_link_libraries(img_viewer PRIVATE ${IMG_VIEWER_LIBS})

set_target_properties(img_viewer PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

message(STATUS "✅ Linked final executable -> img_viewer")
