set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# libc++ を明示的に指定（必要なら）
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-stdlib=libc++)
endif()


cmake_minimum_required(VERSION 3.20)
project(face_detect)

find_package(OpenCV REQUIRED)

add_executable(face_detect src/cpp/face_detect.cpp)
target_link_libraries(face_detect PRIVATE ${OpenCV_LIBS})
