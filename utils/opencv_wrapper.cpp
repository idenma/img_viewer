#include <opencv2/opencv.hpp>
#include <vector>
#include <string>

extern "C" {

// 顔検出して、指定されたサイズにリサイズする関数
// image_path: 入力画像のパス
// output_dir: 出力先ディレクトリ（検出された顔を保存）
// target_width, target_height: 出力サイズ
__declspec(dllexport) int detect_faces(const char* image_path, const char* output_dir, int target_width, int target_height) {
    try {
        cv::CascadeClassifier face_cascade;
        if (!face_cascade.load("haarcascade_frontalface_default.xml")) {
            return -1; // モデル読み込み失敗
        }

        cv::Mat img = cv::imread(image_path);
        if (img.empty()) return -2; // 画像読み込み失敗

        std::vector<cv::Rect> faces;
        face_cascade.detectMultiScale(img, faces, 1.1, 3, 0, cv::Size(50, 50));

        int count = 0;
        for (const auto& face : faces) {
            cv::Mat face_img = img(face).clone();
            cv::resize(face_img, face_img, cv::Size(target_width, target_height));

            std::string filename = std::string(output_dir) + "/face_" + std::to_string(count++) + ".png";
            cv::imwrite(filename, face_img);
        }

        return count; // 検出数を返す
    } catch (...) {
        return -99; // 予期せぬエラー
    }
}
}
