# Codemagic Certificate Fetching Issue - Final Fix

## 🔴 Current Problem
"No valid code signing certificates were found" - Codemagic isn't fetching certificates before build

## ✅ Root Cause
When using `ios_signing` with explicit certificate/profile references, Codemagic needs:
1. **App Store Connect API key** configured in Team settings
2. **Exact name match** between YAML references and uploaded files
3. **Certificates/profiles** must be available in Apple Developer Portal (or uploaded to Codemagic)

## 🔍 Verification Steps

### Step 1: Verify Certificate/Profile Names Match EXACTLY

**In Codemagic Dashboard:**
1. Go to **Teams** → **Code signing identities**
2. **iOS Certificates** tab:
   - Find your certificate: `je-dag-in-beeld-distribution`
   - **Copy the EXACT name** (case-sensitive, including hyphens)
3. **iOS Provisioning Profiles** tab:
   - Find your profile: `jedaginbeeld-release-profile`
   - **Copy the EXACT name** (case-sensitive, including hyphens)

**Compare with codemagic.yaml:**
- Certificate name in YAML: `je-dag-in-beeld-distribution`
- Profile name in YAML: `jedaginbeeld-release-profile`

**⚠️ If names don't match EXACTLY, update codemagic.yaml!**

### Step 2: Verify App Store Connect API Key

**In Codemagic Dashboard:**
1. Go to **Teams** → **Team integrations** → **Developer Portal**
2. Check if App Store Connect API key is configured:
   - Key name: "Steph van Hoffe (Key: 4UL4ZDDG6S)"
   - Status: Active ✅
3. If NOT configured:
   - Go to **Manage keys**
   - Add App Store Connect API key
   - Upload `.p8` file
   - Enter Issuer ID and Key ID

### Step 3: Check Build Logs for Certificate Fetching

**When build runs, look for these messages:**

**✅ Good signs:**
```
Fetching code signing certificates...
Found certificate: je-dag-in-beeld-distribution
Found provisioning profile: jedaginbeeld-release-profile
Installing certificate...
Installing provisioning profile...
```

**❌ Bad signs:**
```
No certificates found matching: je-dag-in-beeld-distribution
No provisioning profiles found matching: jedaginbeeld-release-profile
Failed to fetch certificates from Apple Developer Portal
```

---

## 🔧 Solution Options

### Option 1: Verify Names Match (Most Common Fix)

1. **Check exact names** in Codemagic Team settings
2. **Update codemagic.yaml** if names don't match
3. **Re-run build**

### Option 2: Re-fetch Certificates/Profiles

**In Codemagic Dashboard:**
1. Go to **Teams** → **Code signing identities**
2. **iOS Certificates** tab → Click **"Fetch certificate"**
   - This fetches from Apple Developer Portal using API key
3. **iOS Provisioning Profiles** tab → Click **"Fetch profiles"**
   - This ensures Codemagic has latest profiles

### Option 3: Use Distribution Type Method (Alternative)

If explicit references don't work, try Method 1:

```yaml
ios_signing:
  distribution_type: app_store
  bundle_identifier: com.je-dag-in-beeld.caregiver
```

**Note:** Remove `provisioning_profiles` and `certificates` when using this method!

### Option 4: Check Certificate Expiry

1. Go to **Teams** → **Code signing identities** → **iOS Certificates**
2. Check `je-dag-in-beeld-distribution` expiry date
3. If expired (< 30 days), generate a new certificate

---

## 📋 Diagnostic Script Added

I've added a diagnostic script to your `codemagic.yaml` that will:
- List available certificates in the keychain
- List available provisioning profiles
- Help identify what Codemagic is actually fetching

**Check the build logs** after running the build to see what certificates/profiles are available.

---

## 🎯 Next Steps

1. **Verify exact names** match between Codemagic and codemagic.yaml
2. **Check App Store Connect API key** is configured
3. **Re-fetch certificates/profiles** in Codemagic
4. **Run build** and check diagnostic output
5. **Review build logs** for certificate fetching messages

---

## 🆘 If Still Not Working

**Check build logs for:**
- Certificate name mismatches
- API key authentication errors
- Certificate expiry warnings
- Provisioning profile bundle ID mismatches

**Contact Codemagic Support with:**
- Build logs showing certificate fetching errors
- Certificate name: `je-dag-in-beeld-distribution`
- Profile name: `jedaginbeeld-release-profile`
- Bundle ID: `com.je-dag-in-beeld.caregiver`
