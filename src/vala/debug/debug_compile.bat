@echo off
REM Debug compile for FolderGridView only (does not modify compile.bat)

echo [INFO] Setting up MSYS2 environment (debug)...
if not defined MSYS2_ROOT set "MSYS2_ROOT=F:\msys64"
set "PATH=%MSYS2_ROOT%\mingw64\bin;%MSYS2_ROOT%\usr\bin;%PATH%"
set "PKG_CONFIG_PATH=%MSYS2_ROOT%\mingw64\lib\pkgconfig;%MSYS2_ROOT%\mingw64\share\pkgconfig"
set "XDG_DATA_DIRS=%MSYS2_ROOT%\mingw64\share;%MSYS2_ROOT%\usr\share;%XDG_DATA_DIRS%"
set "GSETTINGS_SCHEMA_DIR=%MSYS2_ROOT%\mingw64\share\glib-2.0\schemas"

echo [INFO] Compiling debug_main.vala (FolderGridView only)...
valac --pkg gtk+-3.0 --pkg gee-0.8 --pkg librsvg-2.0 --pkg cairo ^
    debug_main.vala mainwindow.vala basewindow.vala imagegridview.vala imageflowview.vala foldergridview.vala folderloader.vala imageitem.vala thumbnailer.vala mask.vala random.vala footerbar.vala ^
    -o debug.exe

if %ERRORLEVEL% neq 0 (
    echo [ERROR] Debug compilation failed.
    pause
    exit /b 1
) else (
    echo [INFO] Running debug.exe...
    debug.exe
)
pause
