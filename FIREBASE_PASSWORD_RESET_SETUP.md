# Firebase Password Reset Email Template - Setup Guide

## Overview
This guide will help you set up custom password reset email templates for your Firebase Authentication in the "Je Dag in Beeld" app.

## Files Included
- `FIREBASE_PASSWORD_RESET_TEMPLATE.html` - Dutch version
- `FIREBASE_PASSWORD_RESET_TEMPLATE_ENGLISH.html` - English version

## Setup Instructions

### Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **je-dag-in-beeld**
3. Navigate to **Authentication** in the left sidebar
4. Click on the **Templates** tab

### Step 2: Configure Password Reset Email
1. In the Templates section, find **"Password reset"** template
2. Click on **"Password reset"** to edit it

### Step 3: Configure Email Settings

#### For Dutch Users (Default):
1. **Subject Line:**
   ```
   Reset uw Je Dag in Beeld wachtwoord
   ```

2. **Sender Name:**
   ```
   Je Dag in Beeld Support
   ```

3. **Email Body:**
   - Open `FIREBASE_PASSWORD_RESET_TEMPLATE.html`
   - Copy the entire HTML content
   - Paste it into the "Email Body" field in Firebase Console
   - **IMPORTANT:** Keep the `%LINK%` placeholder - Firebase will replace it automatically

#### For English Users (Optional - if you want separate template):
1. You can create a custom action handler to send different templates based on user language
2. Or use the English template as a reference for manual translation

### Step 4: Configure Action URL (Important!)

1. In the Firebase Console, go to **Authentication → Settings**
2. Scroll down to **Authorized domains**
3. Make sure your app domain is listed (usually added automatically)

4. For **Action URL**, you have two options:

#### Option A: Use Firebase Default (Recommended for Mobile Apps)
- Leave the default Firebase URL
- The link will redirect to your app's deep link
- Configure your app to handle the password reset deep link

#### Option B: Custom Action URL
- Set a custom URL that redirects to your app
- Example: `https://je-dag-in-beeld.app/reset-password?mode=resetPassword&oobCode=%OOB_CODE%`
- Replace `%OOB_CODE%` with the actual code (Firebase handles this)

### Step 5: Test the Email
1. In Firebase Console, go to **Authentication → Users**
2. Find a test user or create one
3. Click on the user and select **"Reset password"**
4. Check the email inbox to verify the template looks correct

## Template Variables

Firebase automatically replaces these placeholders:
- `%LINK%` - The password reset link (DO NOT REMOVE)
- `%EMAIL%` - User's email address (optional, can be added if needed)

## Security Settings

### Password Reset Link Expiry
1. Go to **Authentication → Settings → Password reset**
2. Set **Password reset link expiry** to **1 hour** (recommended)
3. This matches the message in the email template

### Rate Limiting
Firebase automatically limits password reset requests to prevent abuse:
- Default: 5 requests per hour per email address
- This can be adjusted in Firebase Console if needed

## Mobile App Deep Link Configuration

### Android (AndroidManifest.xml)
Add intent filter to handle password reset links:
```xml
<activity android:name=".MainActivity">
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
      android:scheme="https"
      android:host="je-dag-in-beeld.firebaseapp.com"
      android:pathPrefix="/__/auth/action" />
  </intent-filter>
</activity>
```

### iOS (Info.plist)
Add URL scheme:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.je-dag-in-beeld.caregiver</string>
    </array>
  </dict>
</array>
```

## Handling Password Reset in Flutter App

### Example Code (reset_password_screen.dart)
```dart
import 'package:firebase_auth/firebase_auth.dart';

Future<void> sendPasswordResetEmail(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email,
      // Optional: Custom action code settings
      actionCodeSettings: ActionCodeSettings(
        url: 'https://je-dag-in-beeld.app/reset-password',
        handleCodeInApp: true,
        androidPackageName: 'com.je_dag_in_beeld.caregiver',
        iOSBundleId: 'com.je-dag-in-beeld.caregiver',
      ),
    );
    // Show success message
  } on FirebaseAuthException catch (e) {
    // Handle errors
    if (e.code == 'user-not-found') {
      // User doesn't exist
    } else if (e.code == 'too-many-requests') {
      // Too many requests
    }
  }
}
```

## Troubleshooting

### Email Not Received
1. Check spam/junk folder
2. Verify email address is correct
3. Check Firebase Console → Authentication → Users for the user
4. Verify email provider isn't blocking Firebase emails

### Link Not Working
1. Verify link hasn't expired (1 hour default)
2. Check if link was already used (one-time use)
3. Verify app deep link configuration
4. Check Firebase Console → Authentication → Settings → Authorized domains

### Template Not Showing
1. Clear browser cache
2. Verify HTML is valid (no broken tags)
3. Check that `%LINK%` placeholder is present
4. Try sending a test email again

## Best Practices

1. **Keep %LINK% placeholder** - Never remove or modify it
2. **Test regularly** - Send test emails to verify template
3. **Monitor usage** - Check Firebase Console for reset request patterns
4. **Security** - Use 1-hour expiry for reset links
5. **User experience** - Provide clear instructions in the email

## Support

If you encounter issues:
1. Check Firebase Console → Authentication → Settings for configuration
2. Review Firebase documentation: https://firebase.google.com/docs/auth
3. Check app logs for error messages
4. Verify email service is enabled in Firebase project

## Notes

- The email template uses the app's brand color (#4A90E2)
- Template is responsive and works on mobile email clients
- Both Dutch and English versions are provided
- The link expires in 1 hour for security (configurable in Firebase)
