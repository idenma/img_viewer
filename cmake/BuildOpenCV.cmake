set(OPENCV_SOURCES
    ${CMAKE_SOURCE_DIR}/src/vala/utils/opencv_wrapper.cpp
)

add_library(opencv_part STATIC ${OPENCV_SOURCES})
target_include_directories(opencv_part PRIVATE ${OPENCV_INCLUDE_DIRS} ${CMAKE_SOURCE_DIR}/src/vala/utils)
target_link_libraries(opencv_part PRIVATE ${OPENCV_LIBRARIES})

message(STATUS "✅ Built OpenCV part -> opencv_part.lib")
