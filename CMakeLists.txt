cmake_minimum_required(VERSION 3.20)
project(img_viewer C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# OpenCV は face_detect と opencv_wrapper 双方で使用（MSYS2: pkg-config 経由）
find_package(PkgConfig REQUIRED)
pkg_check_modules(OPENCV QUIET opencv4)
if(NOT OPENCV_FOUND)
    message(FATAL_ERROR "pkg-config 経由で OpenCV(opencv4) が見つかりません。MSYS2 の MinGW64 環境で 'pacman -S mingw-w64-x86_64-opencv' を実行してインストールしてください。")
endif()

# --- C++ サンプル（従来どおり） ---
add_executable(face_detect src/cpp/face_detect.cpp)
target_include_directories(face_detect PRIVATE ${OPENCV_INCLUDE_DIRS})
target_link_libraries(face_detect PRIVATE ${OPENCV_LIBRARIES})

# --- オプション: Vala アプリ本体を CMake でビルド ---
option(ENABLE_IMG_VIEWER "Build Vala GTK3 img_viewer app" OFF)

if (ENABLE_IMG_VIEWER)
    include(cmake/BuildOpenCV.cmake)  # -> opencv_part
    include(cmake/BuildVala.cmake)    # -> vala_part
    include(cmake/LinkAll.cmake)      # -> img_viewer
endif()
