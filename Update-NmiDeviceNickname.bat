@echo off
REM Runs Update-NmiDeviceNickname.ps1 with ExecutionPolicy Bypass so it works
REM even if the system's execution policy blocks unsigned scripts.
REM
REM Usage examples (run from cmd or double-click and type args when prompted):
REM
REM   Update-NmiDeviceNickname.bat -ApiKey "your_api_key" -Nickname "Front Counter" -DeviceId "414b0420-b31c-4c76-9fc3-8a4f1a6dcffc"
REM
REM   Update-NmiDeviceNickname.bat -ApiKey "your_api_key" -Nickname "Register 1" -DeviceId "guid1,guid2,guid3"

setlocal
set "SCRIPT_DIR=%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Update-NmiDeviceNickname.ps1" %*

set "EXIT_CODE=%ERRORLEVEL%"
echo.
pause
endlocal & exit /b %EXIT_CODE%
