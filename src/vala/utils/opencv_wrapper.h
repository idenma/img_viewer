#ifndef OPENCV_WRAPPER_H
#define OPENCV_WRAPPER_H

#ifdef _WIN32
#  define EXPORT __declspec(dllexport)
#else
#  define EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// 顔検出関数（Cリンク）
EXPORT int detect_faces(const char* image_path, const char* output_dir, int target_width, int target_height);

#ifdef __cplusplus
}
#endif

#endif // OPENCV_WRAPPER_H
