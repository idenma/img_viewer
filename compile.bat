@echo off
REM ============================================
REM Img_Viewer コンパイルスクリプト for MSYS2 + GTK3
REM --------------------------------------------
REM フォルダ構成に対応：
REM img_viewer/
REM   ├── main.vala
REM   ├── main_window.vala
REM   ├── views/*.vala
REM   ├── utils/*.vala
REM   └── widgets/*.vala
REM ============================================

echo [INFO] Setting up MSYS2 environment...

REM === MSYS2 環境設定 ===
set "MSYS2_ROOT=F:\msys64"
set "PATH=%MSYS2_ROOT%\mingw64\bin;%MSYS2_ROOT%\usr\bin;%PATH%"
set "PKG_CONFIG_PATH=%MSYS2_ROOT%\mingw64\lib\pkgconfig;%MSYS2_ROOT%\mingw64\share\pkgconfig"
set "ACLOCAL_PATH=%MSYS2_ROOT%\mingw64\share\aclocal"

REM === GSettings スキーマ対応 ===
set "XDG_DATA_DIRS=%MSYS2_ROOT%\mingw64\share;%MSYS2_ROOT%\usr\share;%XDG_DATA_DIRS%"
set "GSETTINGS_SCHEMA_DIR=%MSYS2_ROOT%\mingw64\share\glib-2.0\schemas"

echo [INFO] Ensuring GSettings schemas compiled (if available)...
if exist "%GSETTINGS_SCHEMA_DIR%" (
    "%MSYS2_ROOT%\mingw64\bin\glib-compile-schemas.exe" "%GSETTINGS_SCHEMA_DIR%" 2>nul || echo [WARN] glib-compile-schemas failed
) else (
    echo [WARN] GSettings schema dir not found: %GSETTINGS_SCHEMA_DIR%
)

REM === ビルド開始 ===
echo.
echo [INFO] Compiling Img_Viewer sources...

REM === valac ソース一覧 ===
set SOURCES=^
 main.vala ^
 mainwindow.vala ^
 views\basewindow.vala ^
 views\imagegridview.vala ^
 views\imageflowview.vala ^
 views\foldergridview.vala ^
 utils\CairoUtils.vala ^
 utils\SvgUtils.vala ^
 utils\random.vala ^
 utils\thumbnailer.vala ^
 utils\folderscanner.vala ^
 utils\folderloader.vala ^
 widgets\footerbar.vala ^
 widgets\imageitem.vala

REM === 出力ファイル名 ===
set OUTPUT=main.exe

REM === GTK3 / GEE / RSVG / CAIRO ライブラリ ===
valac --pkg gtk+-3.0 --pkg gee-0.8 --pkg librsvg-2.0 --pkg cairo ^
--vapidir=utils --Xcc=-Lutils --Xcc=-lopencv_wrapper ^
--output=%OUTPUT% ^
%SOURCES%


REM === 結果確認 ===
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] ❌ Compilation failed. Please check source files or library paths.
    exit /b 1
) else (
    echo.
    echo [SUCCESS] ✅ Compilation completed successfully!
    echo [INFO] Output file: %OUTPUT%
    echo [INFO] File size:
    dir %OUTPUT% | findstr /i "%OUTPUT%"
)
