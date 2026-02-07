@echo off
echo Cleaning Gradle and build caches to fix metadata.bin / plugin resolution errors...
echo.

set "USER_GRADLE=%USERPROFILE%\.gradle"
set "PROJECT_ANDROID=%~dp0"
set "PROJECT_ROOT=%~dp0.."

echo 1. Stopping Gradle daemons...
call gradle --stop 2>nul
echo.

echo 2. Removing entire user .gradle folder (fixes corrupted metadata.bin / kotlin-dsl)...
if exist "%USER_GRADLE%" (
    rd /s /q "%USER_GRADLE%"
    echo    Deleted %USER_GRADLE%
) else (
    echo    .gradle folder not found, skipping.
)
echo.

echo 3. Removing project android\.gradle and build folders...
if exist "%PROJECT_ANDROID%.gradle" (
    rd /s /q "%PROJECT_ANDROID%.gradle"
    echo    Deleted android\.gradle
)
if exist "%PROJECT_ANDROID%app\build" (
    rd /s /q "%PROJECT_ANDROID%app\build"
    echo    Deleted android\app\build
)
if exist "%PROJECT_ANDROID%build" (
    rd /s /q "%PROJECT_ANDROID%build"
    echo    Deleted android\build
)
echo.

echo 4. Flutter clean...
cd /d "%PROJECT_ROOT%"
call flutter clean
echo.

echo 5. Flutter pub get...
call flutter pub get
echo.

echo Done. Try building again: flutter run or flutter build apk
pause
