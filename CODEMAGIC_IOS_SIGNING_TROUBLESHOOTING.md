# Codemagic iOS Signing Troubleshooting

## 🔴 Current Issue
"No valid code signing certificates were found" even with `ios_signing` configured

## ✅ Current Configuration

Your `codemagic.yaml` now has:
```yaml
ios_signing:
  distribution_type: app_store
  bundle_identifier: com.je-dag-in-beeld.caregiver
integrations:
  app_store_connect: Steph van Hoffe (Key: 4UL4ZDDG6S)
```

## 🔍 Troubleshooting Steps

### Step 1: Verify Certificates/Profiles Are Available

**In Codemagic Dashboard:**
1. Go to **Teams** → **Code signing identities**
2. **iOS Certificates** tab:
   - Verify `je-dag-in-beeld-distribution` exists ✅
   - Check it's type "production" (Apple Distribution) ✅
3. **iOS Provisioning Profiles** tab:
   - Verify App Store profile for `com.je-dag-in-beeld.caregiver` exists ✅
   - Check it's type "App Store" ✅

### Step 2: Verify App Store Connect API Key

**In Codemagic Dashboard:**
1. Go to **Teams** → Check App Store Connect API settings
2. Verify API key "Steph van Hoffe (Key: 4UL4ZDDG6S)" is configured ✅
3. Ensure it has permissions to:
   - Read certificates
   - Read provisioning profiles
   - Access App Store Connect

### Step 3: Check Build Logs

When the build runs, look for these messages in the logs:

**Good signs:**
- ✅ "Fetching code signing certificates..."
- ✅ "Found certificate: je-dag-in-beeld-distribution"
- ✅ "Found provisioning profile for com.je-dag-in-beeld.caregiver"
- ✅ "Code signing configured successfully"

**Bad signs:**
- ❌ "No certificates found matching criteria"
- ❌ "No provisioning profiles found"
- ❌ "Failed to fetch certificates from Apple Developer Portal"

### Step 4: Verify Bundle ID Match

**Critical:** The bundle identifier must match EXACTLY:
- In `codemagic.yaml`: `com.je-dag-in-beeld.caregiver`
- In Provisioning Profile: `com.je-dag-in-beeld.caregiver`
- In Xcode project: `com.je-dag-in-beeld.caregiver`

**Check for typos or differences!**

---

## 🔧 Alternative Solutions

### Option 1: Use Certificate/Profile Names Directly

If `ios_signing` isn't working, try specifying names directly:

```yaml
ios_signing:
  distribution_type: app_store
  bundle_identifier: com.je-dag-in-beeld.caregiver
  certificate_credential_type: distribution
```

### Option 2: Verify API Key Permissions

The App Store Connect API key needs these permissions:
- **Developer** or **Admin** role
- Access to certificates and provisioning profiles
- App Store Connect API access enabled

### Option 3: Check Certificate Expiry

1. Go to **Teams** → **Code signing identities** → **iOS Certificates**
2. Check `je-dag-in-beeld-distribution` expiry date
3. If expired, generate a new certificate

### Option 4: Re-fetch Certificates/Profiles

1. In Codemagic: **Teams** → **Code signing identities**
2. **iOS Certificates** tab → Click **"Fetch certificate"**
3. **iOS Provisioning Profiles** tab → Click **"Fetch profiles"**
4. This ensures Codemagic has the latest from Apple Developer Portal

---

## 📋 Verification Checklist

Before starting a new build, verify:

- [ ] Certificate `je-dag-in-beeld-distribution` exists in Team settings
- [ ] Certificate type is "Apple Distribution" (production)
- [ ] Provisioning profile for `com.je-dag-in-beeld.caregiver` exists
- [ ] Provisioning profile type is "App Store"
- [ ] App Store Connect API key is configured: "Steph van Hoffe (Key: 4UL4ZDDG6S)"
- [ ] Bundle ID matches exactly: `com.je-dag-in-beeld.caregiver`
- [ ] Certificate is not expired
- [ ] `codemagic.yaml` has `ios_signing` configured correctly
- [ ] `codemagic.yaml` references App Store Connect integration

---

## 🆘 If Still Not Working

**Contact Codemagic Support with:**

1. **Build logs** showing the error
2. **codemagic.yaml** content
3. **Certificate name**: `je-dag-in-beeld-distribution`
4. **Provisioning profile**: App Store profile for `com.je-dag-in-beeld.caregiver`
5. **Bundle ID**: `com.je-dag-in-beeld.caregiver`
6. **API Key**: Steph van Hoffe (Key: 4UL4ZDDG6S)

**Ask them:**
- Why `ios_signing` method isn't finding certificates/profiles
- If certificates/profiles need to be fetched from Apple Developer Portal
- If API key permissions are correct
- If there's a different way to configure code signing

---

## 🎯 Next Steps

1. **Verify all items in the checklist above**
2. **Try re-fetching certificates/profiles** in Codemagic
3. **Check build logs** for specific error messages
4. **Contact Codemagic support** if issue persists

---

**The configuration looks correct - the issue might be with certificate/profile availability or API key permissions.**
