@echo off
setlocal ENABLEDELAYEDEXPANSION

call "%~dp0setup_msys2_env.bat" || goto :error

set "GDK_PIXBUF_MODULEDIR=%MSYS2_ROOT%\mingw64\lib\gdk-pixbuf-2.0\2.10.0\loaders"
set "GDK_PIXBUF_MODULE_FILE=%GDK_PIXBUF_MODULEDIR%\loaders.cache"
set PATH=%MSYS2_ROOT%\mingw64\bin;%PATH%

set APP_DIR=%~dp0..\build
if not exist "%APP_DIR%\img_viewer.exe" (
  echo [ERROR] img_viewer.exe not found under %APP_DIR%.
  echo        Run build_img_viewer_mingw.bat first.
  goto :error
)

"%APP_DIR%\img_viewer.exe" %*

endlocal
exit /b 0

:error
endlocal
exit /b 1
