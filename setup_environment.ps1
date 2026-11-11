# ========================================================
# Script tu dong thiet lap moi truong & dong goi APK cho Note NTT
# Ho tro: Android 8.0+ (API 26), 32-bit & 64-bit, Android SDK 36
# ========================================================

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "     KIEM TRA MOI TRUONG PHAT TRIEN NOTE NTT     " -ForegroundColor Cyan
Write-Host "     Ho tro: Android 8.0+ | 32/64-bit | SDK 36   " -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Kiem tra Git
try {
    $gitVer = git --version
    Write-Host "[OK] Git: $gitVer" -ForegroundColor Green
} catch {
    Write-Host "[LOI] Chua cai dat Git." -ForegroundColor Red
    exit 1
}

# 2. Kiem tra Flutter SDK
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
    Write-Host "[OK] Da tim thay Flutter tai: $($flutterCmd.Source)" -ForegroundColor Green
    flutter --version
} else {
    $targetDir = "C:\src\flutter"
    if (Test-Path "$targetDir\bin\flutter.bat") {
        Write-Host "[OK] Tim thay Flutter SDK tai: $targetDir" -ForegroundColor Green
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notlike "*$targetDir\bin*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$targetDir\bin", "User")
            $env:Path += ";$targetDir\bin"
            Write-Host "[OK] Da them $targetDir\bin vao bien moi truong PATH!" -ForegroundColor Green
        }
    }
}

Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "     HUONG DAN DONG GOI APK CHO ANDROID 8+ / SDK 36 " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "1. Cai dat thu vien          : flutter pub get" -ForegroundColor White
Write-Host "2. Build file APK Fat chung  : flutter build apk --release" -ForegroundColor White
Write-Host "3. Build chia tung kien truc : flutter build apk --split-per-abi --release" -ForegroundColor White
Write-Host "   -> armeabi-v7a (32-bit)" -ForegroundColor Gray
Write-Host "   -> arm64-v8a   (64-bit)" -ForegroundColor Gray
Write-Host "   -> x86_64      (64-bit Intel/AMD)" -ForegroundColor Gray
