cmake_minimum_required(VERSION 3.10)
project(OpenCVWrapper)

# vcpkgでインストールしたOpenCVを検索
find_package(OpenCV REQUIRED)

# 明示的に相対パスを指定（F:\GTK3\img_viewer\utils）
add_library(opencv_wrapper SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/utils/opencv_wrapper.cpp
)

target_include_directories(opencv_wrapper PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(opencv_wrapper PRIVATE ${OpenCV_LIBS})
