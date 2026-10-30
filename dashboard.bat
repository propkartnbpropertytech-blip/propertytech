@echo off
title PropKart CRM — Local Release & CI Dashboard
cls
echo =========================================================
echo   PropKart CRM Release & CI Dashboard
echo   Starting local server at http://localhost:5050 ...
echo =========================================================
echo.

start "" "http://localhost:5050"
node tools\release_dashboard\server.js
pause
