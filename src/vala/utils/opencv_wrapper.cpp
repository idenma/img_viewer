#include <opencv2/opencv.hpp>
#include "opencv_wrapper.h"
#include <vector>
#include <string>



// 顔検出して、指定されたサイズにリサイズする関数
// image_path: 入力画像のパス
// output_dir: 出力先ディレクトリ（検出された顔を保存）
// target_width, target_height: 出力サイズ
extern "C" __declspec(dllexport)
int detect_faces(const char* image_path, const char* output_dir, int target_width, int target_height) {
    // 顔検出用分類器（Haar Cascade）: まずはリポジトリ相対 data/ を試す
    cv::CascadeClassifier face_cascade;
    const char* rel_xml = "data/haarcascade_frontalface_default.xml";
    if (!face_cascade.load(rel_xml)) {
        // 互換性のためのフォールバック（従来の絶対パス）。将来的に削除予定。
        const char* legacy_xml = "F:/vcpkg/installed/x64-windows/share/opencv4/haarcascades/haarcascade_frontalface_default.xml";
        if (!face_cascade.load(legacy_xml)) {
            fprintf(stderr, "Error: Could not load Haar cascade XML from '%s' or legacy path.\n", rel_xml);
            return -1;
        }
    }

    // 入力画像を読み込み
    cv::Mat img = cv::imread(image_path);
    if (img.empty()) {
        fprintf(stderr, "Error: Could not load image: %s\n", image_path);
        return -1;
    }

    // グレースケール化
    cv::Mat gray;
    cv::cvtColor(img, gray, cv::COLOR_BGR2GRAY);
    cv::equalizeHist(gray, gray);

    // 顔検出（小さい顔も拾えるように）
    std::vector<cv::Rect> faces;
    face_cascade.detectMultiScale(gray, faces, 1.1, 3, 0, cv::Size(50, 50));

    // 顔が見つからなかった場合
    if (faces.empty()) {
        fprintf(stdout, "No faces detected in %s\n", image_path);
        return 0;
    }

    // 各顔を切り抜いてリサイズして保存
    for (size_t i = 0; i < faces.size(); i++) {
        cv::Rect face_rect = faces[i];

        // 安全のため範囲チェック
        face_rect.x = std::max(face_rect.x, 0);
        face_rect.y = std::max(face_rect.y, 0);
        face_rect.width  = std::min(face_rect.width, img.cols - face_rect.x);
        face_rect.height = std::min(face_rect.height, img.rows - face_rect.y);

        // 顔部分を切り抜く
        cv::Mat faceROI = img(face_rect);

        // 出力サイズにリサイズ（例: 300x300）
        cv::Mat resized;
        cv::resize(faceROI, resized, cv::Size(target_width, target_height));

        // 出力ファイル名
        std::string filename = std::string(output_dir) + "/face_" + std::to_string(i) + ".png";
        cv::imwrite(filename, resized);
    }

    fprintf(stdout, "%zu faces detected and saved.\n", faces.size());
    return static_cast<int>(faces.size());
}