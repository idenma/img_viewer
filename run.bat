@echo off
setlocal

REM ─────────────────────────────────────────────────────────────
REM  GTK3 Vala アプリ ランチャ (MSYS2/MinGW64)
REM  - 必要な環境変数をセット
REM  - GSettings スキーマと gdk-pixbuf ローダを整備
REM  - main.exe (なければ flow.exe/grid.exe) を起動
REM ─────────────────────────────────────────────────────────────

REM 文字コード (日本語メッセージの文字化け対策。失敗しても無視)
chcp 65001 >nul 2>nul

REM MSYS2 ルート。必要なら事前に MSYS2_ROOT を上書き定義してください。
if not defined MSYS2_ROOT set "MSYS2_ROOT=F:\msys64"

set "MINGW_BIN=%MSYS2_ROOT%\mingw64\bin"
set "USR_BIN=%MSYS2_ROOT%\usr\bin"
set "MINGW_SHARE=%MSYS2_ROOT%\mingw64\share"
set "USR_SHARE=%MSYS2_ROOT%\usr\share"
set "MINGW_LIB=%MSYS2_ROOT%\mingw64\lib"

REM カレントをスクリプトの場所へ
pushd "%~dp0" >nul

echo [INFO] MSYS2 root : %MSYS2_ROOT%
if not exist "%MINGW_BIN%\" (
    echo [ERROR] MinGW bin not found: %MINGW_BIN%
    echo        MSYS2 が F:\msys64 に無い場合は MSYS2_ROOT を修正してください。
    goto :EOF
)

REM PATH とデータディレクトリ
set "PATH=%MINGW_BIN%;%USR_BIN%;%PATH%"
set "XDG_DATA_DIRS=%MINGW_SHARE%;%USR_SHARE%;%XDG_DATA_DIRS%"
set "GSETTINGS_SCHEMA_DIR=%MINGW_SHARE%\glib-2.0\schemas"

REM アイコンテーマの有無をチェック (警告のみ)
if not exist "%MINGW_SHARE%\icons\hicolor\" echo [WARN] hicolor icon theme not found. Consider installing: mingw-w64-x86_64-hicolor-icon-theme
if not exist "%MINGW_SHARE%\icons\Adwaita\" echo [WARN] Adwaita icon theme not found. Consider installing: mingw-w64-x86_64-adwaita-icon-theme

REM GSettings スキーマをコンパイル (存在する場合のみ)
if exist "%GSETTINGS_SCHEMA_DIR%" (
    if exist "%MINGW_BIN%\glib-compile-schemas.exe" (
        "%MINGW_BIN%\glib-compile-schemas.exe" "%GSETTINGS_SCHEMA_DIR%" 2>nul || echo [WARN] glib-compile-schemas failed (ignored)
    ) else (
        echo [WARN] glib-compile-schemas.exe not found. Skipping schema compile.
    )
) else (
    echo [WARN] GSETTINGS_SCHEMA_DIR not found: %GSETTINGS_SCHEMA_DIR%
)

REM gdk-pixbuf ローダ設定 (PNG/JPEG/WebP などの読込に必要)
set "GDK_PIXBUF_MODULEDIR=%MINGW_LIB%\gdk-pixbuf-2.0\2.10.0\loaders"
set "GDK_PIXBUF_MODULE_FILE=%MINGW_LIB%\gdk-pixbuf-2.0\2.10.0\loaders.cache"
if exist "%MINGW_BIN%\gdk-pixbuf-query-loaders.exe" (
    "%MINGW_BIN%\gdk-pixbuf-query-loaders.exe" --update-cache 1>nul 2>nul || (
        REM 古い gdk-pixbuf は明示的に出力先を指定
        "%MINGW_BIN%\gdk-pixbuf-query-loaders.exe" > "%GDK_PIXBUF_MODULE_FILE%" 2>nul
    )
) else (
    echo [WARN] gdk-pixbuf-query-loaders.exe not found. Image loaders may be missing.
)

REM 起動する実行ファイルを決定
set "APP_EXE="
if exist "main.exe" set "APP_EXE=main.exe"
if not defined APP_EXE if exist "flow.exe" set "APP_EXE=flow.exe"
if not defined APP_EXE if exist "grid.exe" set "APP_EXE=grid.exe"

if not defined APP_EXE (
    echo [ERROR] Executable not found. Expected one of: main.exe, flow.exe, grid.exe
    goto :END
)

echo [INFO] Launching %APP_EXE% ...
"%CD%\%APP_EXE%" %* 2>&1

:END
popd >nul

REM 対話実行時に一時停止 (環境によっては不要なら rem または set NOPAUSE=1)
if "%NOPAUSE%"=="1" goto :EOF
pause
endlocal
