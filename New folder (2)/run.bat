@echo off
title EmotiGuard Dashboard Launcher
echo ===================================================
echo   Starting EmotiGuard Local Server...
echo ===================================================
python serve.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Python not found or server failed.
    echo Trying with py launcher...
    py serve.py
)
pause
