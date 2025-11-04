# img_viewer – Copilot/AI コーディング用ガイド

このリポジトリは Vala + GTK3 を中心にしたデスクトップ画像ビューアです。AI ツールは下記の前提・流儀を踏まえて、実装提案や変更を行ってください（20–50 行の実務要点）。

## 全体像（アーキテクチャ）
- エントリ: `src/vala/main.vala` → `MainWindow`（`src/vala/mainwindow.vala`）。
- 表示レイヤ: `src/vala/views/`（`ImageGridView`, `ImageFlowView`, `FolderGridView`, 共通基底 `BaseWindow`）。
- ウィジェット: `src/vala/widgets/`（`FooterBar`, `ImageItem`）。Footer の操作でビュー切替。
- ユーティリティ: `src/vala/utils/`（`Thumbnailer`, `FolderLoader/FolderScanner`, `SvgUtils`, `CairoUtils`, `RandomGenerator` 等）。
- OpenCV 連携: `src/vala/utils/opencv_wrapper.{h,cpp,vapi}`（Vala⇔C/C++ ブリッジ）。
- 追加の C++ サンプル: `src/cpp/face_detect.cpp`（DNN/LBP で顔検出）。

データフロー要点
- `MainWindow` が現在のフォルダ/表示モードを管理し、`FooterBar.action` シグナルでビュー切替。
- `FolderGridView` はサブフォルダを走査し、クリックで `ImageFlowView` へ遷移。
- サムネイルは `Thumbnailer.create_image_thumbnail()` がモード別に生成。必要に応じて `SvgUtils` でマスク合成。

## ビルド・実行（現状の前提）
- ルート `CMakeLists.txt` は C++ サンプル（`face_detect`）のみをビルド（OpenCV 必須）。
- `cmake/BuildOpenCV.cmake`, `cmake/BuildVala.cmake`, `cmake/LinkAll.cmake` は分離された実験用スクリプトで、現状ルート CMake に未統合。
- Vala 本体のビルドは valac または追加の CMake 統合が必要。Windows では MSYS2/MinGW の `gtk+-3.0`, `gee-0.8`, `librsvg-2.0`, `cairo` が前提。
- OpenCV は vcpkg の `F:/vcpkg/installed/x64-windows` を期待する箇所があります（パス固定のため注意）。

AI からの具体的提案例（このリポに沿う形）
- ルート CMake に Vala 生成/リンクを統合し、`img_viewer` 実行ファイルを生成する（`BuildVala.cmake`/`BuildOpenCV.cmake` の知見を取り込む）。
- `opencv_wrapper.cpp` の分類器/モデルパスを実行時リソースへ移し、相対パス化（`data/` 参照）。
- アイコンは `icon/` 配下の実在ファイルを参照（未存在名を提案しない）。

## コーディング規約と既存パターン
- クラス: PascalCase（例: ImageGridView）。メソッド: camelCase（例: create_image_thumbnail）。ファイル名は小文字＋下線なしで配置（例: `folderloader.vala`）。
- GTK3 前提（GTK4 コードは提案しない）。描画は Cairo、画像は GdkPixbuf。SVG は `SvgUtils` で合成/マスク。
- ビューは `get_widget()` で `Gtk.Widget` を返し、`MainWindow` が `content_box` に差し替え表示。
- 非同期/逐次追加は `Idle.add` を使用（例: `FolderGridView`, `ImageGridView`）。

## OpenCV 連携（重要な約束）
- VAPI: `src/vala/utils/opencv_wrapper.vapi`
  - `int detect_faces(string image_path, string output_dir, int target_width, int target_height);`
- C++ 側実装: `src/vala/utils/opencv_wrapper.cpp`
  - 現状は `output_dir` を“ディレクトリ”として扱い、`output_dir/face_i.png` を保存。
- Vala 側利用: `Thumbnailer.opencv_face_crop()` は第二引数にファイル名を渡しており契約不一致（要修正）。AI が新規利用コードを提案する際は“出力先ディレクトリ”を渡す前提で記述し、必要なら Vala 側も合わせて修正案を提示。

## 既知の落とし穴（AI 提案時に避ける/直す）
- `Thumbnailer.opencv_face_crop()` は全パスでの return 未網羅（末尾到達で未返却）。早期 return を整理し、デフォルトは `image_path` を返す。
- ルート CMake に Vala ターゲットがない（アプリ本体はビルド不能）。統合または別ビルド手順を必ず明記。
- ハードコードされた絶対パス（OpenCV モデル/カスケード, `F:/...`）は動作環境依存。`data/` 相対参照に切替提案を行う。
- フッターの SVG 名称と `icon/` 実ファイルの不一致に注意。存在するアイコンのみ参照。

## 参考ファイル
- エントリ/画面: `src/vala/main.vala`, `src/vala/mainwindow.vala`
- ビュー: `src/vala/views/{basewindow,imagegridview,imageflowview,foldergridview}.vala`
- ウィジェット: `src/vala/widgets/{footerbar,imageitem}.vala`
- ユーティリティ: `src/vala/utils/{Thumbnailer,FolderLoader,FolderScanner,SvgUtils,CairoUtils}.vala`
- OpenCV 連携: `src/vala/utils/opencv_wrapper.{h,cpp,vapi}`／サンプル `src/cpp/face_detect.cpp`

AI への姿勢
- 変更が大きくなる場合は“計画→合意→実装”の順で進める。
- 既存のユーティリティを優先再利用（特に `Thumbnailer`, `SvgUtils`, `CairoUtils`）。
- すべて日本語で説明。外部依存（OpenCV/GTK3）の前提を明示したうえで具体的に提案する。