@echo off
setlocal ENABLEDELAYEDEXPANSION

call "%~dp0setup_msys2_env.bat" || goto :error

REM Avoid vcpkg auto integration for MSYS2 build
set "VCPKG_ROOT="
set "CMAKE_TOOLCHAIN_FILE="
set "MSYS2_UNIX_ROOT=%MSYS2_ROOT:\=/%"

set BUILD_DIR=%~dp0..\build
if exist "%BUILD_DIR%" rd /s /q "%BUILD_DIR%"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"

cmake -G "MinGW Makefiles" -DENABLE_IMG_VIEWER=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=%MSYS2_UNIX_ROOT%/mingw64/bin/gcc.exe -DCMAKE_CXX_COMPILER=%MSYS2_UNIX_ROOT%/mingw64/bin/g++.exe .. || goto :error_pop
cmake --build . --config Release -j || goto :error_pop

popd

echo [INFO] Build completed. Executables are under build\
exit /b 0

:error_pop
popd
:error
echo [ERROR] Build failed.
exit /b 1
