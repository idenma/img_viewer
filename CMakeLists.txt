cmake_minimum_required(VERSION 3.20)
project(img_viewer C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# libc++ を明示的に指定（必要なら）
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-stdlib=libc++)
endif()

# OpenCV は face_detect と opencv_wrapper 双方で使用
find_package(OpenCV REQUIRED)

# --- C++ サンプル（従来どおり） ---
add_executable(face_detect src/cpp/face_detect.cpp)
target_link_libraries(face_detect PRIVATE ${OpenCV_LIBS})

# --- オプション: Vala アプリ本体を CMake でビルド ---
option(ENABLE_IMG_VIEWER "Build Vala GTK3 img_viewer app" OFF)

if (ENABLE_IMG_VIEWER)
    include(cmake/BuildOpenCV.cmake)  # -> opencv_part
    include(cmake/BuildVala.cmake)    # -> vala_part
    include(cmake/LinkAll.cmake)      # -> img_viewer
endif()
