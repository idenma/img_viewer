REM OpenCV のインストール先に合わせて調整
set VCPKG_ROOT=f:\vcpkg
set INCLUDE_DIR=%VCPKG_ROOT%\installed\x64-windows\include
set LIB_DIR=%VCPKG_ROOT%\installed\x64-windows\lib

REM 1. C++ ラッパーをコンパイル
g++ -c -I"%INCLUDE_DIR%" opencv_wrapper.cpp -o opencv_wrapper.o

REM 2. DLL 付きでリンク
g++ opencv_wrapper.o -L"%LIB_DIR%" -lopencv_core450 -lopencv_imgproc450 -lopencv_objdetect450 -lopencv_imgcodecs450 -shared -o opencv_wrapper.dll

REM 3. Vala コードをコンパイル
valac FaceCrop.vala -X opencv_wrapper.dll
