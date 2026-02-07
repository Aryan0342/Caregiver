@echo off
REM Workaround: Build release AAB via Gradle directly to avoid Flutter's
REM "failed to strip debug symbols from native libraries" check (known on Windows).
REM The AAB produced is valid for Play Store upload.

echo Building release app bundle via Gradle...
cd /d "%~dp0"

call flutter pub get
if errorlevel 1 exit /b 1

cd android
call gradlew.bat bundleRelease
if errorlevel 1 (
  cd ..
  exit /b 1
)
cd ..

REM This project redirects Android build dir to ../../build (see android/build.gradle.kts)
set AAB=build\app\outputs\bundle\release\app-release.aab
if exist "%AAB%" (
  echo.
  echo Success. AAB for Play Store:
  echo   %AAB%
) else (
  echo AAB not found at %AAB%
  exit /b 1
)
