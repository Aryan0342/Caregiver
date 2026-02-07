@echo off
echo Fixing Gradle "exclusive access" / timeout lock...
echo.

echo 1. Stopping all Gradle daemons (releases file locks)...
call gradle --stop 2>nul
timeout /t 2 /nobreak >nul
echo.

echo 2. Killing any remaining Java/Gradle processes...
taskkill /f /im java.exe 2>nul
taskkill /f /im gradle.exe 2>nul
timeout /t 2 /nobreak >nul
echo.

set "GRADLE_DISTS=%USERPROFILE%\.gradle\wrapper\dists\gradle-8.14-all"
echo 3. Removing Gradle 8.14 dist folder so it can be re-downloaded...
if exist "%GRADLE_DISTS%" (
    rd /s /q "%GRADLE_DISTS%"
    echo    Deleted %GRADLE_DISTS%
) else (
    echo    Folder not found, skipping.
)
echo.

echo Done. Close this window, then run: flutter run
echo (First build will re-download Gradle - may take a few minutes.)
pause
