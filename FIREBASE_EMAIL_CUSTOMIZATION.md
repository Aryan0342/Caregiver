# Firebase Email Customization Guide

This guide covers how to customize both **Password Reset** and **Email Verification** emails in Firebase Auth.

## How to Customize Email Templates

Firebase Auth emails are customizable through the Firebase Console. To customize them (including the app name shown in the email), you need to edit the email template in Firebase Console.

### Steps to Customize:

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project: `caregiver-cba18`

2. **Navigate to Email Templates**
   - Go to **Authentication** (left sidebar)
   - Click on **Templates** tab (at the top)
   - Select **Password reset** from the list

3. **Customize the Email Template**

   **Sender Name:**
   - Change from default to: `Je Dag in Beeld` or `Je Dag in Beeld Support`
   - This is what appears in the "From" field

   **Subject Line:**
   - Default: "Reset your caregiver-cba18 password"
   - Change to: "Reset uw Je Dag in Beeld wachtwoord" (Dutch)
   - Or: "Reset your Je Dag in Beeld password" (English)

   **Email Body:**
   - Firebase supports **HTML formatting** for email templates
   - You can customize the message text with HTML tags
   - Must keep `%LINK%` placeholder (this is the reset link)
   - Can use these placeholders:
     - `%APP_NAME%` - Will show your app name (if set in project settings)
     - `%LINK%` - The password reset link (REQUIRED - replace in HTML `<a href="%LINK%">` tags)
     - `%EMAIL%` - User's email address
   - **Important:** Use proper HTML structure with `<html>`, `<body>` tags for best formatting

   **Example Customized Body (Dutch with HTML formatting):**
   ```
   <html>
   <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
     <p>Hallo,</p>
     
     <p>Volg deze link om uw Je Dag in Beeld wachtwoord te resetten voor uw %EMAIL% account.</p>
     
     <p style="margin: 20px 0;">
       <a href="%LINK%" style="background-color: #4A90E2; color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: bold;">
         Wachtwoord Resetten
       </a>
     </p>
     
     <p style="color: #666; font-size: 14px;">
       Of kopieer en plak deze link in uw browser:<br>
       <a href="%LINK%" style="color: #4A90E2; word-break: break-all;">%LINK%</a>
     </p>
     
     <p style="color: #999; font-size: 12px; margin-top: 30px;">
       Als u dit verzoek niet heeft gedaan, kunt u dit bericht negeren.
     </p>
     
     <p style="margin-top: 30px;">
       Met vriendelijke groet,<br>
       <strong>Het Je Dag in Beeld team</strong>
     </p>
   </body>
   </html>
   ```
   
   **Alternative Plain Text Version (if HTML is not supported):**
   ```
   Hallo,
   
   Volg deze link om uw Je Dag in Beeld wachtwoord te resetten voor uw %EMAIL% account.
   
   %LINK%
   
   Als u dit verzoek niet heeft gedaan, kunt u dit bericht negeren.
   
   Met vriendelijke groet,
   Het Je Dag in Beeld team
   ```

4. **Set App Display Name (Recommended)**
   - Go to **Project Settings** (gear icon)
   - Under **General** tab, find **Public settings**
   - Set **Project name** or **App nickname** to: `Je Dag in Beeld`
   - This will make `%APP_NAME%` placeholder show "Je Dag in Beeld"

5. **Improve Email Deliverability (Reduce Spam)**
   - Consider setting up a **Custom Domain** for emails
   - In **Templates** tab, click on "Edit" next to sender email
   - Add your own domain (requires DNS configuration)
   - This significantly reduces spam classification

### Important Notes:

- Changes to email templates take effect immediately for new emails
- The `%LINK%` placeholder is REQUIRED - don't remove it
- Language-specific templates can be added (Dutch/English)
- Custom domain requires DNS setup (SPF/DKIM records)

### Current Issue:

The email shows "caregiver-cba18" because:
- Firebase uses the project ID by default
- The `%APP_NAME%` placeholder isn't configured
- App display name isn't set in project settings

After following the steps above, the email will show "Je Dag in Beeld" instead of "caregiver-cba18".

---

## Email Verification Template

### Steps to Customize Email Verification:

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project: `caregiver-cba18`

2. **Navigate to Email Templates**
   - Go to **Authentication** (left sidebar)
   - Click on **Templates** tab (at the top)
   - Select **Email address verification** from the list

3. **Customize the Email Template**

   **Sender Name:**
   - Change from default to: `Je Dag in Beeld` or `Je Dag in Beeld Support`
   - This is what appears in the "From" field

   **Subject Line:**
   - Default: "Verify your caregiver-cba18 email"
   - Change to: "Verifieer uw Je Dag in Beeld e-mailadres" (Dutch)
   - Or: "Verify your Je Dag in Beeld email address" (English)

   **Email Body (HTML Format):**
   ```
   <html>
   <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
     <div style="background-color: #f5f5f5; padding: 30px; border-radius: 12px;">
       <div style="text-align: center; margin-bottom: 30px;">
         <h1 style="color: #4A90E2; margin: 0; font-size: 28px; font-weight: bold;">
           Je Dag in Beeld
         </h1>
       </div>
       
       <div style="background-color: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
         <p style="font-size: 16px; margin-bottom: 20px;">
           Hallo,
         </p>
         
         <p style="font-size: 16px; margin-bottom: 20px;">
           Bedankt voor uw registratie bij Je Dag in Beeld!
         </p>
         
         <p style="font-size: 16px; margin-bottom: 30px;">
           Klik op de knop hieronder om uw e-mailadres te verifiëren en uw account te activeren:
         </p>
         
         <div style="text-align: center; margin: 30px 0;">
           <a href="%LINK%" style="background-color: #4A90E2; color: #ffffff; padding: 16px 32px; text-decoration: none; border-radius: 8px; display: inline-block; font-weight: bold; font-size: 18px;">
             E-mailadres verifiëren
           </a>
         </div>
         
         <p style="font-size: 14px; color: #666; margin-top: 30px;">
           Of kopieer en plak deze link in uw browser:<br>
           <a href="%LINK%" style="color: #4A90E2; word-break: break-all; font-size: 14px;">%LINK%</a>
         </p>
         
         <p style="font-size: 14px; color: #999; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
           Deze link is 3 dagen geldig. Als u deze e-mail niet heeft aangevraagd, kunt u deze negeren.
         </p>
       </div>
       
       <div style="text-align: center; margin-top: 30px; color: #999; font-size: 12px;">
         <p style="margin: 0;">
           Met vriendelijke groet,<br>
           <strong>Het Je Dag in Beeld team</strong>
         </p>
       </div>
     </div>
   </body>
   </html>
   ```

   **Email Body (Plain Text Alternative - if HTML is not supported):**
   ```
   Hallo,
   
   Bedankt voor uw registratie bij Je Dag in Beeld!
   
   Klik op de link hieronder om uw e-mailadres te verifiëren en uw account te activeren:
   
   %LINK%
   
   Deze link is 3 dagen geldig. Als u deze e-mail niet heeft aangevraagd, kunt u deze negeren.
   
   Met vriendelijke groet,
   Het Je Dag in Beeld team
   ```

   **English Version (HTML):**
   ```
   <html>
   <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
     <div style="background-color: #f5f5f5; padding: 30px; border-radius: 12px;">
       <div style="text-align: center; margin-bottom: 30px;">
         <h1 style="color: #4A90E2; margin: 0; font-size: 28px; font-weight: bold;">
           Your Day in View
         </h1>
       </div>
       
       <div style="background-color: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
         <p style="font-size: 16px; margin-bottom: 20px;">
           Hello,
         </p>
         
         <p style="font-size: 16px; margin-bottom: 20px;">
           Thank you for registering with Your Day in View!
         </p>
         
         <p style="font-size: 16px; margin-bottom: 30px;">
           Please click the button below to verify your email address and activate your account:
         </p>
         
         <div style="text-align: center; margin: 30px 0;">
           <a href="%LINK%" style="background-color: #4A90E2; color: #ffffff; padding: 16px 32px; text-decoration: none; border-radius: 8px; display: inline-block; font-weight: bold; font-size: 18px;">
             Verify Email Address
           </a>
         </div>
         
         <p style="font-size: 14px; color: #666; margin-top: 30px;">
           Or copy and paste this link into your browser:<br>
           <a href="%LINK%" style="color: #4A90E2; word-break: break-all; font-size: 14px;">%LINK%</a>
         </p>
         
         <p style="font-size: 14px; color: #999; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
           This link is valid for 3 days. If you did not request this email, you can ignore it.
         </p>
       </div>
       
       <div style="text-align: center; margin-top: 30px; color: #999; font-size: 12px;">
         <p style="margin: 0;">
           Best regards,<br>
           <strong>The Your Day in View team</strong>
         </p>
       </div>
     </div>
   </body>
   </html>
   ```

### Important Notes for Email Verification:

- The `%LINK%` placeholder is **REQUIRED** - don't remove it
- Verification links expire after 3 days by default (Firebase setting)
- The email will automatically include the user's email address (%EMAIL% if needed)
- Use HTML formatting for better appearance in email clients
- Test the email after customization to ensure it displays correctly

### Customization Tips:

1. **Colors**: The template uses `#4A90E2` (app's primary blue) - match your app theme
2. **Language**: Use Dutch for Dutch users, English for English users (if you support multiple languages, create separate templates in Firebase)
3. **Branding**: Include your app logo if available (as an image URL, not attached file)
4. **Accessibility**: Use clear, simple language suitable for caregivers

### Testing:

After customizing, test the verification email by:
1. Creating a test account
2. Checking your inbox (and spam folder)
3. Verifying the link works correctly
4. Ensuring the email looks good on mobile and desktop
