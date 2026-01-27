# PowerShell script to fix Kotlin compilation cache issues
# Run this if you encounter Kotlin daemon compilation errors

Write-Host "Cleaning Flutter build cache..." -ForegroundColor Yellow
flutter clean

Write-Host "Stopping Gradle daemon..." -ForegroundColor Yellow
cd android
.\gradlew --stop
cd ..

Write-Host "Removing Kotlin cache directories..." -ForegroundColor Yellow
if (Test-Path "build") {
    Get-ChildItem -Path "build" -Recurse -Filter "*kotlin*" -Directory | Remove-Item -Recurse -Force
    Write-Host "Kotlin cache directories removed" -ForegroundColor Green
}

Write-Host "Removing .gradle cache..." -ForegroundColor Yellow
if (Test-Path "$env:USERPROFILE\.gradle\caches") {
    Remove-Item -Path "$env:USERPROFILE\.gradle\caches\kotlin-*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Gradle Kotlin cache removed" -ForegroundColor Green
}

Write-Host "`nDone! Try running 'flutter run' again." -ForegroundColor Green
Write-Host "If the issue persists, restart your IDE and try again." -ForegroundColor Yellow
