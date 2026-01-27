@echo off
REM Script to create Android signing keystore for production builds
REM This creates the keystore file needed for Google Play Store uploads

echo ==========================================
echo Android Keystore Creation Script
echo ==========================================
echo.
echo This script will create a keystore file for signing your Android app.
echo You'll need this keystore to upload your app to Google Play Store.
echo.
echo IMPORTANT:
echo - Save the passwords you enter - you'll need them for future updates!
echo - Keep the keystore file safe - if lost, you cannot update your app!
echo.

REM Navigate to script directory
cd /d "%~dp0"

REM Check if keytool is available
set "KEYTOOL_CMD="
where keytool >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "KEYTOOL_CMD=keytool"
    goto :keytool_found
)

REM Try to find keytool in Android Studio's bundled JDK
if exist "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" (
    echo Found keytool in Android Studio JDK.
    set "KEYTOOL_CMD=C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
    goto :keytool_found
)

if exist "C:\Program Files (x86)\Android\Android Studio\jbr\bin\keytool.exe" (
    echo Found keytool in Android Studio JDK.
    set "KEYTOOL_CMD=C:\Program Files (x86)\Android\Android Studio\jbr\bin\keytool.exe"
    goto :keytool_found
)

REM If we get here, keytool was not found
echo ERROR: keytool not found!
echo.
echo keytool is part of Java JDK. Please install Java JDK and ensure it's in your PATH.
echo You can download it from: https://www.oracle.com/java/technologies/downloads/
echo.
echo Or if you have Android Studio installed, ensure it's at:
echo   C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe
echo.
echo After installing Java, restart this script.
pause
exit /b 1

:keytool_found
REM Verify KEYTOOL_CMD is set
if "%KEYTOOL_CMD%"=="" (
    echo ERROR: Failed to locate keytool.
    pause
    exit /b 1
)

REM Check if keystore already exists
if exist "android\app\upload-keystore.jks" (
    echo WARNING: upload-keystore.jks already exists!
    echo Location: android\app\upload-keystore.jks
    echo.
    set /p OVERWRITE="Do you want to overwrite it? (y/N): "
    if /i not "%OVERWRITE%"=="y" (
        echo Aborted. Keeping existing keystore.
        exit /b 0
    )
    echo.
)

REM Create keystore
echo ==========================================
echo Creating keystore...
echo ==========================================
echo.
echo You'll be prompted for the following information:
echo.
echo 1. Keystore password (remember this - you'll need it for builds!)
echo    - Must be at least 6 characters
echo    - Can use same password for keystore and key
echo.
echo 2. Key password (can be same as keystore password)
echo    - Press Enter to use same password as keystore
echo.
echo 3. Your information:
echo    - First and last name (e.g., Jan Jansen)
echo    - Organizational unit (e.g., Development OR your name)
echo      Note: For individuals, you can use your name or "Development"
echo    - Organization name (e.g., Your Name OR "Personal")
echo      Note: For individuals, you can use your name
echo    - City or locality (e.g., Amsterdam)
echo    - State or province (e.g., Noord-Holland)
echo    - Two-letter country code (e.g., NL for Netherlands)
echo.
echo TIP: For individual developers without a company:
echo   - Organizational Unit: Use your name or "Development"
echo   - Organization Name: Use your name or "Personal"
echo   These fields are just for identification and don't affect your app.
echo.
echo Press any key to continue...
pause >nul
echo.

"%KEYTOOL_CMD%" -genkey -v -keystore android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storetype JKS

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo Keystore created successfully!
    echo ==========================================
    echo.
    echo Next steps:
    echo.
    echo 1. Create android\key.properties file:
    echo    - Copy android\key.properties.template to android\key.properties
    echo    - Edit android\key.properties and replace:
    echo      * YOUR_KEYSTORE_PASSWORD_HERE with your keystore password
    echo      * YOUR_KEY_PASSWORD_HERE with your key password
    echo.
    echo 2. Verify the storeFile path in key.properties is:
    echo    storeFile=../app/upload-keystore.jks
    echo.
    echo The keystore file is located at:
    echo   android\app\upload-keystore.jks
    echo.
    echo IMPORTANT SECURITY NOTES:
    echo - Keep this keystore file and passwords secure!
    echo - Store them in a safe location (password manager recommended)
    echo - If you lose the keystore, you cannot update your app on Play Store!
    echo - android\key.properties is already in .gitignore (won't be committed)
    echo.
    echo After creating key.properties, you can build your release app with:
    echo   flutter build appbundle --release
    echo.
) else (
    echo.
    echo ==========================================
    echo ERROR: Failed to create keystore
    echo ==========================================
    echo.
    echo Please check the error messages above.
    echo.
    echo Common issues:
    echo - Passwords don't match
    echo - Password too short (must be at least 6 characters)
    echo - Invalid input format
    echo.
    echo Try running the script again.
    echo.
    exit /b 1
)

pause
