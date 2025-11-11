@echo off
echo ========================================
echo   DATING APP - Serveur Web Local  
echo ========================================
echo.
echo Demarrage sur http://localhost:8080
echo Appuyez sur Ctrl+C pour arreter
echo ========================================
echo.
cd build\web
start http://localhost:8080
python -m http.server 8080
