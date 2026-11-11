@echo off
chcp 65001 > nul
echo ========================================================
echo    DANG KHOI CHAY THIET LAP MOI TRUONG FLUTTER
echo ========================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_environment.ps1"
echo.
pause
