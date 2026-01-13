# Firestore Security Rules Setup

## Issue
You're getting a permission error: `Missing or insufficient permissions` when trying to save pictogram sets to Firestore.

## Solution

I've created `firestore.rules` with proper security rules that allow authenticated users to:
- Create their own pictogram sets
- Read their own pictogram sets
- Update their own pictogram sets
- Delete their own pictogram sets

## How to Deploy the Rules

### Option 1: Using Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `caregiver-cba18`
3. Navigate to **Firestore Database** in the left menu
4. Click on the **Rules** tab
5. Copy the contents of `firestore.rules` file
6. Paste it into the rules editor
7. Click **Publish**

### Option 2: Using Firebase CLI

1. Install Firebase CLI (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase (if not already done):
   ```bash
   firebase init firestore
   ```
   - Select your existing project: `caregiver-cba18`
   - Use the existing `firestore.rules` file

4. Deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Security Rules Explanation

The rules ensure that:
- ✅ Only authenticated users can access pictogram sets
- ✅ Users can only read/write their own sets (based on `userId` field)
- ✅ When creating a set, the `userId` must match the authenticated user's ID
- ✅ All other collections are denied by default

## Testing

After deploying the rules:
1. Make sure you're logged in to the app
2. Try creating a new pictogram set
3. The permission error should be resolved

## Important Notes

- The rules are now configured in `firestore.rules`
- The `firebase.json` has been updated to reference the rules file
- Rules take effect immediately after deployment
- For development, you can temporarily use more permissive rules, but always restrict in production
