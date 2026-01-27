#!/bin/bash

# Script to create Android signing keystore for production builds
# This creates the keystore file needed for Google Play Store uploads

echo "=========================================="
echo "Android Keystore Creation Script"
echo "=========================================="
echo ""
echo "This script will create a keystore file for signing your Android app."
echo "You'll need this keystore to upload your app to Google Play Store."
echo ""
echo "IMPORTANT:"
echo "- Save the passwords you enter - you'll need them for future updates!"
echo "- Keep the keystore file safe - if lost, you cannot update your app!"
echo ""

# Navigate to project root
cd "$(dirname "$0")"

# Check if keystore already exists
if [ -f "android/app/upload-keystore.jks" ]; then
    echo "WARNING: upload-keystore.jks already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Keeping existing keystore."
        exit 1
    fi
fi

# Create keystore
echo ""
echo "Creating keystore..."
echo "You'll be prompted for:"
echo "  - Keystore password (remember this!)"
echo "  - Key password (can be same as keystore password)"
echo "  - Your name and organization details"
echo ""

keytool -genkey -v \
    -keystore android/app/upload-keystore.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias upload

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Keystore created successfully!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Create android/key.properties file with your passwords"
    echo "2. Use the template: android/key.properties.template"
    echo ""
    echo "The keystore file is located at:"
    echo "  android/app/upload-keystore.jks"
    echo ""
    echo "⚠️  IMPORTANT: Keep this file and passwords secure!"
    echo "   Add android/key.properties to .gitignore (already done)"
    echo ""
else
    echo ""
    echo "❌ Error creating keystore. Please check the error messages above."
    exit 1
fi
