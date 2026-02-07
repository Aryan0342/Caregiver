# Android build failed: not enough disk space

The error **"There is not enough space on the disk"** means your C: drive (or the drive where Gradle stores caches) is full. Gradle cannot download Flutter engine JARs or create transform directories.

## Fix: free disk space, then retry

### 1. Free space on C: drive

- Delete unneeded files, empty Recycle Bin, uninstall unused programs.
- Move large folders (e.g. Videos, Downloads) to another drive if you have one.
- Aim for **at least 5–10 GB free** on C: for a comfortable Android build.

### 2. Clear Gradle caches (releases several GB)

In PowerShell or Command Prompt run:

```batch
rd /s /q "%USERPROFILE%\.gradle\caches"
```

Then run your build again. Gradle will re-download what it needs (requires internet).

### 3. Clear Flutter build cache (optional)

From your project folder (`Caregiver\Caregiver`):

```batch
flutter clean
```

### 4. Retry the build

```batch
flutter pub get
flutter build apk
```

or run from your IDE (e.g. Run > Debug).

---

**If you have another drive with more space:** you can point Gradle to use it by setting `GRADLE_USER_HOME` (e.g. `D:\gradle-home`) before running the build, so caches and transforms are stored there instead of on C:.
