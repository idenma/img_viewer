#include <opencv2/opencv.hpp>
#include <opencv2/dnn.hpp>
#include <iostream>
#include <filesystem>

namespace fs = std::filesystem;

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: face_detect <image_file>\n";
        return 1;
    }

    std::string imagePath = argv[1];
    cv::Mat img = cv::imread(imagePath);
    if (img.empty()) {
        std::cerr << "Error: Could not load image: " << imagePath << "\n";
        return 1;
    }

    std::cout << "Loaded image: " << imagePath << " (" << img.cols << "x" << img.rows << ")\n";

    // DNNモデルのパス（相対 data/ を優先し、Caffe→TensorFlow の順で試す）
    cv::dnn::Net net;
    bool dnnLoaded = false;
    {
        // 1) Caffe (res10 + deploy.prototxt)
        std::string caffeModel = "data/res10_300x300_ssd_iter_140000.caffemodel";
        std::string caffeProto = "data/deploy.prototxt";
        try {
            net = cv::dnn::readNetFromCaffe(caffeProto, caffeModel);
            dnnLoaded = !net.empty();
        } catch (...) {
            dnnLoaded = false;
        }
    }
    if (!dnnLoaded) {
        // 2) TensorFlow (pb + pbtxt)
        std::string tfModel = "data/opencv_face_detector_uint8.pb";
        std::string tfConfig = "data/opencv_face_detector.pbtxt"; // 無ければ失敗
        try {
            net = cv::dnn::readNetFromTensorflow(tfModel, tfConfig);
            dnnLoaded = !net.empty();
        } catch (...) {
            dnnLoaded = false;
        }
        if (!dnnLoaded) {
            std::cerr << "⚠️ DNNモデルが読み込めません。Haar/LBP分類器にフォールバックします。\n";
        }
    }

    int width = img.cols;
    int height = img.rows;
    float conf_threshold = 0.1f;

    int faceCount = 0;
    float bestConfidence = 0.0f;
    cv::Mat bestFace;

    if (dnnLoaded && !net.empty()) {
        cv::Mat blob = cv::dnn::blobFromImage(img, 1.0, cv::Size(300, 300),
                                              cv::Scalar(104.0, 177.0, 123.0), false, false);
        net.setInput(blob);
        cv::Mat detections = net.forward();

        cv::Mat detectionMat(detections.size[2], detections.size[3], CV_32F, detections.ptr<float>());
        int totalDetections = detectionMat.rows;

        std::cout << "DNN produced " << totalDetections << " candidate detections\n";

        for (int i = 0; i < totalDetections; i++) {
            float confidence = detectionMat.at<float>(i, 2);
            if (confidence < conf_threshold) continue;

            int x1 = static_cast<int>(detectionMat.at<float>(i, 3) * width);
            int y1 = static_cast<int>(detectionMat.at<float>(i, 4) * height);
            int x2 = static_cast<int>(detectionMat.at<float>(i, 5) * width);
            int y2 = static_cast<int>(detectionMat.at<float>(i, 6) * height);

            x1 = std::clamp(x1, 0, width - 1);
            y1 = std::clamp(y1, 0, height - 1);
            x2 = std::clamp(x2, 0, width - 1);
            y2 = std::clamp(y2, 0, height - 1);

            cv::Rect box(x1, y1, x2 - x1, y2 - y1);
            if (box.width <= 0 || box.height <= 0) continue;

            faceCount++;
            cv::Mat face = img(box).clone();

            // === 縦横比維持して300x300へ ===
            int targetSize = 300;
            cv::Mat resized;
            double sx = static_cast<double>(targetSize) / face.cols;
            double sy = static_cast<double>(targetSize) / face.rows;
            double scale = (sx < sy) ? sx : sy;
            cv::resize(face, resized, cv::Size(), scale, scale);

            int top = (targetSize - resized.rows) / 2;
            int bottom = targetSize - resized.rows - top;
            int left = (targetSize - resized.cols) / 2;
            int right = targetSize - resized.cols - left;
            cv::copyMakeBorder(resized, resized, top, bottom, left, right,
                               cv::BORDER_CONSTANT, cv::Scalar(0, 0, 0));

            // 保存
            std::string outName = "face_" + std::to_string(faceCount) + ".png";
            cv::imwrite(outName, resized);

            std::cout << "  [" << faceCount << "] conf=" << confidence
                      << " box=(" << x1 << "," << y1 << "," << box.width << "x" << box.height << ")\n"
                      << "    -> Saved " << outName << " (300x300)\n";

            if (confidence > bestConfidence) {
                bestConfidence = confidence;
                bestFace = resized.clone();
            }

            cv::rectangle(img, box, cv::Scalar(0, 255, 0), 2);
        }

        cv::imwrite("result.png", img);
        std::cout << "Saved overall result: result.png\n";
    }

    // === DNNで検出できなかった場合は LBPアニメ分類器を使用 ===
    if (faceCount == 0) {
        std::cerr << "No DNN faces detected, trying LBP anime cascade...\n";
        cv::CascadeClassifier animeFaceCascade;
        if (!animeFaceCascade.load("F:/GTK3/img_viewer/data/lbpcascade_animeface.xml")) {
            std::cerr << "Failed to load lbpcascade_animeface.xml\n";
            return 1;
        }

        std::vector<cv::Rect> animeFaces;
        animeFaceCascade.detectMultiScale(img, animeFaces, 1.1, 5, 0, cv::Size(24, 24));

        std::cout << "Anime cascade detected " << animeFaces.size() << " faces\n";

        for (size_t i = 0; i < animeFaces.size(); i++) {
            cv::Rect face = animeFaces[i];
            cv::Mat crop = img(face).clone();

            int targetSize = 300;
            cv::Mat resized;
            double sx = static_cast<double>(targetSize) / crop.cols;
            double sy = static_cast<double>(targetSize) / crop.rows;
            double scale = (sx < sy) ? sx : sy;
            cv::resize(crop, resized, cv::Size(), scale, scale);

            int top = (targetSize - resized.rows) / 2;
            int bottom = targetSize - resized.rows - top;
            int left = (targetSize - resized.cols) / 2;
            int right = targetSize - resized.cols - left;
            cv::copyMakeBorder(resized, resized, top, bottom, left, right,
                               cv::BORDER_CONSTANT, cv::Scalar(0, 0, 0));

            std::string outName = "anime_face_" + std::to_string(i + 1) + ".png";
            cv::imwrite(outName, resized);
            std::cout << "Saved (anime): " << outName << "\n";
        }
    }

    // === 最良の1枚を保存 ===
    if (!bestFace.empty()) {
        cv::imwrite("best_face.png", bestFace);
        std::cout << "✅ Saved best detected face as best_face.png (confidence = " << bestConfidence << ")\n";
    }

    std::cout << "Total faces saved: " << faceCount << "\n";
    return 0;
}
