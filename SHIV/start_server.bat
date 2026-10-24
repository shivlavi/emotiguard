@echo off
title EmotiGuard Full-Stack Server
cd /d "c:\Users\palj2\OneDrive\Desktop\SHIV"
echo ========================================================
echo        Starting EmotiGuard Backend Server
echo ========================================================
echo.
echo Local PC URL:       http://localhost:8000/demo
echo API Documentation:  http://localhost:8000/docs
echo.
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
pause
