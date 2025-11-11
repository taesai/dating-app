@echo off
echo ========================================
echo DEPLOIEMENT FLUTTER WEB
echo ========================================
echo.

echo [1/4] Nettoyage...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors du nettoyage
    exit /b 1
)

echo.
echo [2/4] Installation des dependances...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de l'installation des dependances
    exit /b 1
)

echo.
echo [3/4] Build production...
call flutter build web --release --web-renderer html
if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors du build
    exit /b 1
)

echo.
echo [4/4] Build termine avec succes!
echo Le dossier build/web est pret pour le deploiement
echo.
echo Pour deployer sur Netlify:
echo   1. Allez sur https://app.netlify.com
echo   2. Drag & drop le dossier build/web
echo   OU
echo   3. Utilisez: netlify deploy --prod --dir=build/web
echo.
pause
