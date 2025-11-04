@echo off
REM Setup MSYS2 MinGW64 environment for building Vala + GTK3

if not defined MSYS2_ROOT set "MSYS2_ROOT=F:\msys64"

set "PATH=%MSYS2_ROOT%\mingw64\bin;%MSYS2_ROOT%\usr\bin;%PATH%"
set "PKG_CONFIG_PATH=%MSYS2_ROOT%\mingw64\lib\pkgconfig;%MSYS2_ROOT%\mingw64\share\pkgconfig"
set "XDG_DATA_DIRS=%MSYS2_ROOT%\mingw64\share;%MSYS2_ROOT%\usr\share;%XDG_DATA_DIRS%"
set "GSETTINGS_SCHEMA_DIR=%MSYS2_ROOT%\mingw64\share\glib-2.0\schemas"

where pkg-config >NUL 2>&1
if %ERRORLEVEL% neq 0 (
  echo [ERROR] pkg-config not found in PATH. Ensure MSYS2 is installed under %MSYS2_ROOT% and packages are installed.
  exit /b 1
)

echo [INFO] MSYS2 MinGW64 environment configured.
exit /b 0
