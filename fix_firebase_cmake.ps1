# Script to fix Firebase CMake compatibility issue
# Run this script if you encounter CMake errors related to Firebase SDK

$firebaseCmakePath = "build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"

if (Test-Path $firebaseCmakePath) {
    Write-Host "Fixing Firebase CMakeLists.txt..." -ForegroundColor Yellow
    
    $content = Get-Content $firebaseCmakePath -Raw
    $content = $content -replace 'cmake_minimum_required\(VERSION 3\.1\)', 'cmake_minimum_required(VERSION 3.5)'
    
    Set-Content -Path $firebaseCmakePath -Value $content -NoNewline
    
    Write-Host "Fixed! Updated CMake minimum version from 3.1 to 3.5" -ForegroundColor Green
} else {
    Write-Host "Firebase CMakeLists.txt not found. Run 'flutter build windows' first to extract the SDK." -ForegroundColor Yellow
}
