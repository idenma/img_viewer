# img_viewer (Vala + GTK3) / face_detect (OpenCV)

軽量なデスクトップ画像ビューア（Vala + GTK3）と、OpenCV 顔検出の C++ サンプルを含むリポジトリです。

- 画像ビューア本体: `src/vala`
- OpenCV サンプル: `src/cpp/face_detect.cpp`
- DNN/カスケード等のモデル: `data/`

本 README は Windows + MSYS2/MinGW64 での最小ビルド手順をまとめています。

## 必要環境（MSYS2/MinGW64）

1) MSYS2 をインストールし、"MSYS2 MinGW 64-bit" シェルを開く
2) 依存パッケージをインストール

```bash
pacman -S --needed \
  git \
  mingw-w64-x86_64-toolchain \
  mingw-w64-x86_64-cmake \
  mingw-w64-x86_64-pkg-config \
  mingw-w64-x86_64-opencv \
  mingw-w64-x86_64-gtk3 \
  mingw-w64-x86_64-vala \
  mingw-w64-x86_64-libgee \
  mingw-w64-x86_64-librsvg \
  mingw-w64-x86_64-cairo \
  mingw-w64-x86_64-gdk-pixbuf2
```

補足
- OpenCV は CMake の `find_package(OpenCV)` で検出します（MSYS2 パッケージで可）。
- Vala/GTK 側は pkg-config で検出します。

## 1) C++ サンプル（face_detect）のビルド

このターゲットは標準で有効です。最初はこれが通ることを確認してください。

```bash
# リポジトリ直下
mkdir -p build && cd build
cmake -G "MinGW Makefiles" ..
cmake --build . --config Release -j
```

出力
- `build/face_detect.exe`

実行例（注意: data/ への相対参照）
- `face_detect` は実行ディレクトリから `data/` を相対参照します。以下のいずれかで実行してください。
  - a) リポジトリルートに戻って実行: `./build/face_detect.exe path/to/image.jpg`
  - b) `build/` に `data/` フォルダをコピーしてから `build/` で実行

```bash
# a) ルートから実行（推奨）
./build/face_detect.exe pola.png

# b) build/ に data/ を複製してから build/ で実行
cp -r ../data ./
./face_detect.exe pola.png
```

## 2) 画像ビューア本体（Vala + GTK3）のビルド（実験的）

CMake オプション `ENABLE_IMG_VIEWER=ON` で有効化します。MSYS2 で `gtk3/vala/libgee/librsvg/cairo` が導入済みであることが前提です。

方法A（推奨）: MSYS2 MinGW64 シェルで実行
```bash
# リポジトリ直下
mkdir -p build && cd build
cmake -G "MinGW Makefiles" -DENABLE_IMG_VIEWER=ON ..
cmake --build . --config Release -j
```

方法B: Windows PowerShell / cmd からバッチで実行（MSYS2 を F:\\msys64 にインストールした場合）
```bat
REM リポジトリ直下
scripts\build_img_viewer_mingw.bat
```

出力
- `build/img_viewer.exe`

実行
```bash
# 既定では引数なしで起動、または開始フォルダを渡す
./img_viewer.exe "D:/Pictures"
```

注意点（現状）
- Vala の CMake 統合は最小実装です。ビルドに失敗する場合は、MSYS2 のパッケージが揃っているか確認してください。
- 実行時、OpenCV のカスケード/モデルは `data/` を相対参照します（`opencv_wrapper.cpp`）。`img_viewer.exe` の隣、または実行ディレクトリから相対で `data/` が見えるようにしてください。
- 顔検出結果は `output_faces/` に保存されます（自動生成）。

## ディレクトリ構成（抜粋）

```
img_viewer/
├─ src/
│  ├─ cpp/              # C++ 顔検出サンプル
│  └─ vala/             # 画像ビューア本体
│     ├─ views/         # ImageGridView / ImageFlowView / FolderGridView
│     ├─ widgets/       # FooterBar / ImageItem
│     └─ utils/         # Thumbnailer / SvgUtils / CairoUtils / ...
├─ data/                # DNN/カスケード等のモデル
└─ icon/                # SVG/PNG アイコン
```

## トラブルシューティング

- OpenCV が見つからない
  - `pacman -S mingw-w64-x86_64-opencv` を再実行。`cmake ..` のログで OpenCV パスが解決されているか確認。
- GTK/gee/librsvg/cairo のシンボルでリンク失敗
  - MSYS2 の対応パッケージをインストールしてください（上記コマンド参照）。
- `data/` が見つからない
  - 実行ディレクトリから `data/` が相対参照できるよう、ルートで実行するか `data/` を隣に配置してください。

## ライセンス
リポジトリ内のコード/設定はプロジェクトのライセンスに従います。`data/` 内の各モデル/カスケードは配布元のライセンス条項を参照してください。
