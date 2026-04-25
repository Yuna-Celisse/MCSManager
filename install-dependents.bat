@echo off
setlocal EnableExtensions

set "ROOT_DIR=%~dp0"

echo ------------------------------------------------------------
echo MCSManager dependency installer (Windows)
echo ------------------------------------------------------------

pushd "%ROOT_DIR%" >nul 2>&1
if errorlevel 1 (
	echo [ERROR] Failed to enter workspace: "%ROOT_DIR%"
	goto :failed
)

where npm >nul 2>&1
if errorlevel 1 (
	echo [ERROR] npm is not available in PATH.
	echo [HINT] Install Node.js 16+ and reopen this terminal.
	goto :failed
)

where curl >nul 2>&1
if errorlevel 1 (
	echo [ERROR] curl is not available in PATH.
	echo [HINT] Install curl or run this script on Windows 10+.
	goto :failed
)

set "SRC_GITHUB=https://github.com"
set "SRC_MIRROR_1=https://mirror.ghproxy.com/https://github.com"
set "SRC_MIRROR_2=https://ghproxy.net/https://github.com"

echo [1/6] Installing workspace dependencies...
call npm install
if errorlevel 1 goto :failed

echo [2/6] Building common package preview...
call npm run preview-build
if errorlevel 1 goto :failed

echo [3/6] Installing daemon dependencies...
pushd daemon >nul 2>&1
if errorlevel 1 (
	echo [ERROR] Missing directory: daemon
	goto :failed
)

call npm install
if errorlevel 1 goto :failed_daemon

if not exist lib (
	echo [INFO] Creating daemon\lib directory...
	mkdir lib
	if errorlevel 1 goto :failed_daemon
)

echo [INFO] Downloading daemon runtime binaries...
call :download_file "lib\file_zip_win32_x64.exe" "%SRC_GITHUB%/MCSManager/Zip-Tools/releases/download/latest/file_zip_win32_x64.exe" "%SRC_MIRROR_1%/MCSManager/Zip-Tools/releases/download/latest/file_zip_win32_x64.exe" "%SRC_MIRROR_2%/MCSManager/Zip-Tools/releases/download/latest/file_zip_win32_x64.exe"
if errorlevel 1 goto :failed_daemon

call :download_file "lib\7z_win32_x64.exe" "%SRC_GITHUB%/MCSManager/Zip-Tools/releases/download/latest/7z_win32_x64.exe" "%SRC_MIRROR_1%/MCSManager/Zip-Tools/releases/download/latest/7z_win32_x64.exe" "%SRC_MIRROR_2%/MCSManager/Zip-Tools/releases/download/latest/7z_win32_x64.exe"
if errorlevel 1 goto :failed_daemon

call :download_file "lib\pty_win32_x64.exe" "%SRC_GITHUB%/MCSManager/PTY/releases/download/latest/pty_win32_x64.exe" "%SRC_MIRROR_1%/MCSManager/PTY/releases/download/latest/pty_win32_x64.exe" "%SRC_MIRROR_2%/MCSManager/PTY/releases/download/latest/pty_win32_x64.exe"
if errorlevel 1 goto :failed_daemon

popd

echo [4/6] Installing panel dependencies...
pushd panel >nul 2>&1
if errorlevel 1 (
	echo [ERROR] Missing directory: panel
	goto :failed
)
call npm install
if errorlevel 1 goto :failed_panel
popd

echo [5/6] Installing frontend dependencies...
pushd frontend >nul 2>&1
if errorlevel 1 (
	echo [ERROR] Missing directory: frontend
	goto :failed
)
call npm install
if errorlevel 1 goto :failed_frontend
popd

echo [6/6] Completed.
echo ------------------------------------------------------------
echo All dependencies installed successfully.
echo Run .\npm-dev-windows.bat to start the development environment.
echo ------------------------------------------------------------
popd
pause
exit /b 0

:download_file
set "OUT=%~1"
set "URL_1=%~2"
set "URL_2=%~3"
set "URL_3=%~4"

echo [DOWNLOAD] %OUT%

call :try_download "%OUT%" "%URL_1%"
if not errorlevel 1 exit /b 0

if not "%URL_2%"=="" (
	call :try_download "%OUT%" "%URL_2%"
	if not errorlevel 1 exit /b 0
)

if not "%URL_3%"=="" (
	call :try_download "%OUT%" "%URL_3%"
	if not errorlevel 1 exit /b 0
)

echo [ERROR] All download sources failed for %OUT%
exit /b 1

:try_download
set "OUT=%~1"
set "URL=%~2"
echo [SOURCE] %URL%
curl -fL --retry 2 --retry-delay 2 --connect-timeout 15 -o "%OUT%" "%URL%"
if errorlevel 1 (
	echo [WARN] Source failed: %URL%
	if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1
	exit /b 1
)

for %%I in ("%OUT%") do (
	if %%~zI lss 1 (
		echo [WARN] Downloaded file is empty: %URL%
		del /f /q "%OUT%" >nul 2>&1
		exit /b 1
	)
)

echo [OK] Downloaded: %OUT%
exit /b 0

:failed_daemon
popd
goto :failed

:failed_panel
popd
goto :failed

:failed_frontend
popd
goto :failed

:failed
echo ------------------------------------------------------------
echo [ERROR] Dependency installation failed.
echo ------------------------------------------------------------
popd >nul 2>&1
pause
exit /b 1