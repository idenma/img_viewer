#include <opencv2/opencv.hpp>
#include <opencv2/dnn.hpp>
#include <iostream>
#include <filesystem>
#include <algorithm>

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

    // data ディレクトリの検索パスを決定（実行ファイル位置 / build / 現在ディレクトリを順に試す）
    std::vector<fs::path> dataRoots;
    try {
        fs::path exePath = fs::canonical(fs::path(argv[0]));
        fs::path exeDir = exePath.parent_path();
        dataRoots.push_back(exeDir / "data");            // 例: build/data
        dataRoots.push_back(exeDir.parent_path() / "data"); // 例: repo/data
    } catch (...) {
        // canonical 失敗時は無視
    }
    dataRoots.push_back(fs::current_path() / "data");

    auto resolveDataFile = [&](const std::string& name) -> fs::path {
        for (const auto& root : dataRoots) {
            if (root.empty()) continue;
            fs::path candidate = root / name;
            if (fs::exists(candidate)) {
                return fs::canonical(candidate);
            }
        }
        return fs::path();
    };

    // DNNモデルのパス（Caffe→TensorFlow の順で試す）
    cv::dnn::Net net;
    bool dnnLoaded = false;
    {
        // 1) Caffe (res10 + deploy.prototxt)
        fs::path caffeModel = resolveDataFile("res10_300x300_ssd_iter_140000.caffemodel");
        fs::path caffeProto = resolveDataFile("deploy.prototxt");
        if (!caffeModel.empty() && !caffeProto.empty()) {
            try {
                net = cv::dnn::readNetFromCaffe(caffeProto.string(), caffeModel.string());
                dnnLoaded = !net.empty();
            } catch (...) {
                dnnLoaded = false;
            }
        }
        if (!dnnLoaded) {
            std::cerr << "Warning: Caffe DNN models not found or failed to load.\n";
        }
    }
    if (!dnnLoaded) {
        // 2) TensorFlow (pb + pbtxt)
        fs::path tfModel = resolveDataFile("opencv_face_detector_uint8.pb");
        fs::path tfConfig = resolveDataFile("opencv_face_detector.pbtxt");
        if (!tfModel.empty() && !tfConfig.empty()) {
            try {
                net = cv::dnn::readNetFromTensorflow(tfModel.string(), tfConfig.string());
                dnnLoaded = !net.empty();
            } catch (...) {
                dnnLoaded = false;
            }
        }
        if (!dnnLoaded) {
            std::cerr << "Warning: DNN could not be loaded. Falling back to Haar/LBP cascades.\n";
        }
    }

    int width = img.cols;
    int height = img.rows;
    float conf_threshold = 0.1f;

    float bestConfidence = 0.0f;
    cv::Mat bestFace;
    cv::Rect bestBox;
    bool bestFromDnn = false;

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

            if (confidence > bestConfidence) {
                bestConfidence = confidence;
                cv::Mat face = img(box).clone();
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

                bestFace = resized.clone();
                bestBox = box;
                bestFromDnn = true;
            }
        }
    }

    // === DNNで検出できなかった場合は LBPアニメ分類器を使用 ===
    if (!bestFromDnn) {
        std::cerr << "No DNN faces detected, trying LBP anime cascade...\n";
        cv::CascadeClassifier animeFaceCascade;
        fs::path animeCascade = resolveDataFile("lbpcascade_animeface.xml");
        if (animeCascade.empty() || !animeFaceCascade.load(animeCascade.string())) {
            std::cerr << "Failed to load lbpcascade_animeface.xml\n";
            return 1;
        }

        std::vector<cv::Rect> animeFaces;
        animeFaceCascade.detectMultiScale(img, animeFaces, 1.1, 5, 0, cv::Size(24, 24));
        if (!animeFaces.empty()) {
            auto bestIt = std::max_element(animeFaces.begin(), animeFaces.end(),
                [](const cv::Rect& a, const cv::Rect& b) {
                    return a.area() < b.area();
                });
            cv::Rect face = *bestIt;
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

            bestFace = resized.clone();
            bestBox = face;
            bestConfidence = 0.0f; // no confidence score from cascade
            std::cout << "Anime cascade fallback succeeded (single face selected).\n";
        } else {
            std::cerr << "Anime cascade detected 0 faces.\n";
        }
    }

    // === 最良の1枚を保存 ===
    if (!bestFace.empty()) {
        cv::imwrite("best_face.png", bestFace);
        if (bestFromDnn) {
            std::cout << "Saved best detected face as best_face.png (confidence = " << bestConfidence << ")\n";
        } else {
            std::cout << "Saved best detected face as best_face.png (cascade fallback)\n";
        }

        if (bestBox.width > 0 && bestBox.height > 0) {
            cv::Mat annotated = img.clone();
            cv::rectangle(annotated, bestBox, cv::Scalar(0, 255, 0), 2);
            cv::imwrite("result.png", annotated);
            std::cout << "Saved overall result: result.png\n";
        }
    }

    if (bestFace.empty()) {
        std::cout << "No face crops were produced.\n";
    }
    return 0;
}
