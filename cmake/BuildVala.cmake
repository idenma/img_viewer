find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)
find_package(Vala REQUIRED)
include(${VALA_USE_FILE})

# --- Valaソースを自動検索 ---
# F:/GTK3/img_viewer/ 以下のすべての .vala ファイルを再帰的に検索
file(GLOB_RECURSE VALA_SOURCES
    "${CMAKE_SOURCE_DIR}/src/vala/*.vala"
)

# --- 検出されたファイル一覧を表示（デバッグ用）---
message(STATUS "🔍 Found Vala sources:")
foreach(vala_file ${VALA_SOURCES})
    message(STATUS "    ${vala_file}")
endforeach()

vala_precompile(VALA_C
    ${VALA_SOURCES}
    PACKAGES gtk+-3.0
)

add_library(vala_part STATIC ${VALA_C})
target_include_directories(vala_part PRIVATE ${GTK3_INCLUDE_DIRS})
target_link_libraries(vala_part PRIVATE ${GTK3_LIBRARIES})

message(STATUS "✅ Built Vala part -> vala_part.lib")
