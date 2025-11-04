@echo off
setlocal ENABLEDELAYEDEXPANSION

call "%~dp0setup_msys2_env.bat" || goto :error

set BUILD_DIR=%~dp0..\build
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"

cmake -G "MinGW Makefiles" -DENABLE_IMG_VIEWER=ON .. || goto :error_pop
cmake --build . --config Release -j || goto :error_pop

popd

echo [INFO] Build completed. Executables are under build\
exit /b 0

:error_pop
popd
:error
echo [ERROR] Build failed.
exit /b 1
