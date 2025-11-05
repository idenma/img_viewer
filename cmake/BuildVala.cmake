find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)
pkg_check_modules(GEE REQUIRED gee-0.8)
pkg_check_modules(RSVG REQUIRED librsvg-2.0)
pkg_check_modules(CAIRO REQUIRED cairo)
pkg_check_modules(GDKPB REQUIRED gdk-pixbuf-2.0)

# Find valac directly to avoid toolchain overrides
find_program(VALA_EXECUTABLE NAMES valac)
if(NOT VALA_EXECUTABLE)
    message(FATAL_ERROR "valac not found. Ensure MSYS2 'mingw-w64-x86_64-vala' is installed and PATH is configured.")
endif()

include(${CMAKE_SOURCE_DIR}/cmake/UseVala.cmake)

# --- Valaソースを自動検索 ---
# F:/GTK3/img_viewer/ 以下のすべての .vala ファイルを再帰的に検索
file(GLOB_RECURSE VALA_SOURCES "${CMAKE_SOURCE_DIR}/src/vala/*.vala")
# 除外: デバッグ用/旧版の重複エントリやコピー
list(FILTER VALA_SOURCES EXCLUDE REGEX ".*/src/vala/debug/.*")
list(FILTER VALA_SOURCES EXCLUDE REGEX ".*/src/vala/views/grid\\.vala$")
list(FILTER VALA_SOURCES EXCLUDE REGEX ".*/src/vala/views/thumbnailer_copy.*\\.vala$")
list(FILTER VALA_SOURCES EXCLUDE REGEX ".*/src/vala/utils/FaceCrop\\.vala$")

set(VAPI_FILES "${CMAKE_SOURCE_DIR}/src/vala/utils/opencv_wrapper.vapi")
set(VAPI_DIRS  "${CMAKE_SOURCE_DIR}/src/vala/utils")

# --- 検出されたファイル一覧を表示（デバッグ用）---
message(STATUS "🔍 Found Vala sources:")
foreach(vala_file ${VALA_SOURCES})
    message(STATUS "    ${vala_file}")
endforeach()

vala_precompile(VALA_C
    TARGET img_viewer
    SOURCES ${VALA_SOURCES}
    VAPIS ${VAPI_FILES}
    VAPIDIRS ${VAPI_DIRS}
    PACKAGES gtk+-3.0 gee-0.8 librsvg-2.0 cairo gdk-pixbuf-2.0
    OPTIONS --target-glib=2.0
)

add_library(vala_part STATIC ${VALA_C})
target_include_directories(vala_part PRIVATE
    ${GTK3_INCLUDE_DIRS}
    ${GEE_INCLUDE_DIRS}
    ${RSVG_INCLUDE_DIRS}
    ${CAIRO_INCLUDE_DIRS}
    ${GDKPB_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/src/vala/utils
)
target_link_libraries(vala_part PRIVATE
    ${GTK3_LIBRARIES}
    ${GEE_LIBRARIES}
    ${RSVG_LIBRARIES}
    ${CAIRO_LIBRARIES}
    ${GDKPB_LIBRARIES}
)

message(STATUS "✅ Built Vala part -> vala_part.lib")
