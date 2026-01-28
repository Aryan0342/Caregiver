# Codemagic Support Request - Code Signing Group Creation

## 📧 Request to Codemagic Support

**Subject**: Need help creating code signing group for iOS builds

**Message Template**:

---

Hello Codemagic Support,

I need help creating a code signing group for my iOS app builds. I have certificates and provisioning profiles configured in Team settings, but I cannot create a code signing group through the UI.

**App Details:**
- App Name: Caregiver
- Repository: [Your GitHub/GitLab repo URL]
- Bundle ID: `com.je-dag-in-beeld.caregiver`

**Certificates & Profiles Available in Team Settings:**
- Certificate Name: `je-dag-in-beeld-distribution`
- Certificate Type: Apple Distribution (production)
- Provisioning Profile: App Store profile for `com.je-dag-in-beeld.caregiver`

**What I Need:**
Please create a code signing group with the following:
- **Group Name**: `app_store_credentials`
- **Certificate**: `je-dag-in-beeld-distribution`
- **Provisioning Profile**: App Store profile for `com.je-dag-in-beeld.caregiver`

This group is referenced in my `codemagic.yaml` file:
```yaml
groups:
  - app_store_credentials
```

Currently, builds fail with "No valid code signing certificates were found" because the group doesn't exist.

Thank you for your assistance!

---

## 🔍 How to Contact Codemagic Support

1. **In Codemagic Dashboard:**
   - Look for "Support" or "Help" link (usually in bottom right or top navigation)
   - Click the chat bubble icon (if available)
   - Or go to: https://codemagic.io/contact/

2. **Via Email:**
   - support@codemagic.io

3. **Documentation:**
   - Check: https://docs.codemagic.io/

---

## ✅ After Group is Created

Once Codemagic support creates the `app_store_credentials` group:

1. **Verify in Codemagic:**
   - Go to Teams → Code signing identities
   - Check if "Groups" tab/section appears
   - Verify `app_store_credentials` group exists

2. **Your codemagic.yaml is already configured:**
   - The group reference is already in your YAML file ✅

3. **Start a new build:**
   - Builds should now succeed and produce `.ipa` files ✅

---

## 📋 Information to Provide Support

- **Account Email**: aryan.nasir4321@gmail.com
- **Team Name**: Steph van hoffe
- **Certificate Name**: je-dag-in-beeld-distribution
- **Provisioning Profile**: App Store profile for com.je-dag-in-beeld.caregiver
- **Group Name Needed**: app_store_credentials
- **Bundle ID**: com.je-dag-in-beeld.caregiver

---

**Next Step**: Contact Codemagic support using the message template above!
