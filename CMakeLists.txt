cmake_minimum_required(VERSION 3.20)
project(img_viewer C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)

option(BUILD_FACE_DETECT "Build face_detect sample application" ON)
option(ENABLE_IMG_VIEWER "Build Vala GTK3 img_viewer app" ON)
option(ENABLE_OPENCV_FACE "Enable OpenCV face cropping for folder icons" OFF)

if (BUILD_FACE_DETECT OR ENABLE_OPENCV_FACE)
    pkg_check_modules(OPENCV QUIET opencv4)
    if(NOT OPENCV_FOUND)
        message(FATAL_ERROR "OpenCV(opencv4) が見つかりません。MSYS2 の MinGW64 環境で 'pacman -S mingw-w64-x86_64-opencv' を実行してインストールしてください。")
    endif()
endif()

if (BUILD_FACE_DETECT)
    add_executable(face_detect src/cpp/face_detect.cpp)
    target_include_directories(face_detect PRIVATE ${OPENCV_INCLUDE_DIRS})
    target_link_libraries(face_detect PRIVATE ${OPENCV_LIBRARIES})
endif()

if (ENABLE_IMG_VIEWER)
    include(cmake/BuildVala.cmake)
    if (ENABLE_OPENCV_FACE)
        include(cmake/BuildOpenCV.cmake)
    endif()
    include(cmake/LinkAll.cmake)
endif()
