@echo off
REM Remove generated face detection images and temporary outputs.
setlocal

set "TARGET_DIR=%~1"
if not defined TARGET_DIR set "TARGET_DIR=%~dp0..\build"

if not exist "%TARGET_DIR%" (
    echo [INFO] Target directory not found: %TARGET_DIR%
    exit /b 0
)

pushd "%TARGET_DIR%" >NUL

del /q "face_*.png" 2>NUL
del /q "anime_face_*.png" 2>NUL
del /q "result.png" 2>NUL
del /q "best_face.png" 2>NUL
del /q "*_face.png" 2>NUL

if exist "output_faces" (
    echo [INFO] Removing output_faces directory...
    rd /s /q "output_faces"
)

popd >NUL

echo [INFO] Removed generated face detection outputs under %TARGET_DIR%
exit /b 0
