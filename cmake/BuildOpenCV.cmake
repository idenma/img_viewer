find_package(OpenCV REQUIRED PATHS "F:/vcpkg/installed/x64-windows")

set(OPENCV_SOURCES
    ${CMAKE_SOURCE_DIR}/src/cpp/opencv_wrapper.cpp
)

add_library(opencv_part STATIC ${OPENCV_SOURCES})
target_include_directories(opencv_part PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(opencv_part PRIVATE ${OpenCV_LIBS})

message(STATUS "✅ Built OpenCV part -> opencv_part.lib")
