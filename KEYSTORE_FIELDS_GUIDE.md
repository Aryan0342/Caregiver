# Android Keystore Fields Guide - For Individual Developers

When creating the Android keystore, you'll be asked for several fields. Here's what each means and what to enter if you're an individual developer (salaried person) without a company.

## Fields Explained

### 1. **First and Last Name** (CN - Common Name)
**What it is:** Your full name

**What to enter:**
- Your full name (e.g., "John Doe" or "Jan Jansen")
- This identifies you as the certificate owner

**Example:** `Jan Jansen`

---

### 2. **Organizational Unit** (OU)
**What it is:** Department or division within an organization

**For individual developers, you can use:**
- Your name again
- "Development" or "App Development"
- "Personal" or "Individual"
- Your profession (e.g., "Software Development")

**Examples:**
- `Jan Jansen` (your name)
- `Development`
- `App Development`
- `Personal`

**Recommendation:** Use your name or "Development"

---

### 3. **Organization Name** (O)
**What it is:** Company or organization name

**For individual developers, you can use:**
- Your full name (e.g., "Jan Jansen")
- "Personal" or "Individual Developer"
- Your profession (e.g., "Software Developer")
- If you have a business name, use that

**Examples:**
- `Jan Jansen` (your name - most common for individuals)
- `Personal`
- `Individual Developer`
- `Jan Jansen Development` (if you want to be more specific)

**Recommendation:** Use your full name

---

### 4. **City or Locality** (L)
**What it is:** City where you're located

**What to enter:**
- Your city name (e.g., "Amsterdam", "Rotterdam", "Utrecht")

**Example:** `Amsterdam`

---

### 5. **State or Province** (ST)
**What it is:** State or province name

**What to enter:**
- Your province name (e.g., "Noord-Holland", "Zuid-Holland", "Utrecht")
- For Netherlands: Use province name in Dutch

**Examples:**
- `Noord-Holland`
- `Zuid-Holland`
- `Utrecht`
- `Gelderland`

---

### 6. **Two-letter Country Code** (C)
**What it is:** ISO country code

**What to enter:**
- Two letters only (e.g., "NL" for Netherlands, "US" for United States)

**Examples:**
- `NL` (Netherlands)
- `BE` (Belgium)
- `DE` (Germany)
- `US` (United States)

---

## Complete Example for Individual Developer

**Name:** Jan Jansen  
**Organizational Unit:** Development  
**Organization:** Jan Jansen  
**City:** Amsterdam  
**State/Province:** Noord-Holland  
**Country Code:** NL

---

## Important Notes

✅ **These fields are for identification only** - They don't affect app functionality  
✅ **You can use your personal name** - No company required  
✅ **Keep it simple** - Use your name for organization if unsure  
✅ **These cannot be changed later** - But they don't matter much for Play Store

---

## What Matters Most

The **really important** things are:
1. ✅ **Keystore password** - Save this securely!
2. ✅ **Key password** - Save this securely!
3. ✅ **Keep the keystore file safe** - You'll need it for all future updates

The organizational fields are just metadata and won't affect your app's functionality or Play Store submission.
