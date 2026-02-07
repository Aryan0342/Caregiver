@echo off
echo Stopping Gradle and unlocking build...
echo.

echo 1. Stopping Gradle daemons...
call gradle --stop 2>nul
timeout /t 2 /nobreak >nul
echo.

echo 2. Killing Java/Gradle processes (including PID 20248 if still running)...
taskkill /f /im java.exe 2>nul
taskkill /f /im gradle.exe 2>nul
if not "%~1"=="" taskkill /f /pid 20248 2>nul
timeout /t 2 /nobreak >nul
echo.

set "PROJECT_ANDROID=%~dp0"
set "USER_GRADLE=%USERPROFILE%\.gradle"

echo 3. Removing project lock and cache (android\.gradle)...
if exist "%PROJECT_ANDROID%.gradle" (
    rd /s /q "%PROJECT_ANDROID%.gradle"
    echo    Deleted android\.gradle
) else (
    echo    android\.gradle not found
)
echo.

echo 4. Removing Gradle 8.14 dist (so zip can be re-downloaded without lock)...
if exist "%USER_GRADLE%\wrapper\dists\gradle-8.14-all" (
    rd /s /q "%USER_GRADLE%\wrapper\dists\gradle-8.14-all"
    echo    Deleted gradle-8.14-all dist
) else (
    echo    gradle-8.14-all dist not found
)
echo.

echo Done. Now:
echo   - Close ALL terminals and IDEs that might run Flutter/Gradle
echo   - Open ONE new terminal
echo   - cd to project and run: flutter run
echo.
pause
