# ========================================================
# Script tu dong thiet lap Flutter SDK cho du an Note NTT
# ========================================================

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "     KIEM TRA MOI TRUONG PHAT TRIEN NOTE NTT     " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Kiem tra Git
try {
    $gitVer = git --version
    Write-Host "[OK] Da tim thay Git: $gitVer" -ForegroundColor Green
} catch {
    Write-Host "[LOI] Chua cai dat Git. Vui long cai Git truoc." -ForegroundColor Red
    exit 1
}

# 2. Kiem tra Flutter SDK
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
    Write-Host "[OK] Da tim thay Flutter tai: $($flutterCmd.Source)" -ForegroundColor Green
    flutter --version
} else {
    Write-Host "[THONG BAO] Flutter SDK chua co trong PATH." -ForegroundColor Yellow
    
    $targetDir = "C:\src\flutter"
    if (Test-Path "E:\flutter") { $targetDir = "E:\flutter" }
    elseif (Test-Path "C:\flutter") { $targetDir = "C:\flutter" }
    elseif (Test-Path "C:\src\flutter") { $targetDir = "C:\src\flutter" }

    if (Test-Path "$targetDir\bin\flutter.bat") {
        Write-Host "[TIM THAY] Tim thay Flutter SDK tai: $targetDir" -ForegroundColor Green
        Write-Host "Dang tu dong them vao bien moi truong PATH cua User..." -ForegroundColor Cyan
        
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notlike "*$targetDir\bin*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$targetDir\bin", "User")
            $env:Path += ";$targetDir\bin"
            Write-Host "[THANH CONG] Da them $targetDir\bin vao PATH!" -ForegroundColor Green
        }
    } else {
        Write-Host "`nBan co muon tu dong tai Flutter SDK bang Git ve '$targetDir' khong?" -ForegroundColor Yellow
        Write-Host "Lua chon:" -ForegroundColor White
        Write-Host "  1. Chay lenh Git Clone de tu dong tai va cai dat Flutter" -ForegroundColor White
        Write-Host "  2. Hoac tai thu cong file zip tu trang chu: https://docs.flutter.dev/get-started/install/windows/mobile" -ForegroundColor White
        
        $choice = Read-Host "`nNhap 'Y' de tu dong cai dat bang Git (hoac 'N' de tu tai qua trinh duyet)"
        if ($choice -eq 'Y' -or $choice -eq 'y') {
            Write-Host "`nDang tai Flutter SDK tu GitHub (qua trinh nay mat khoang 2-5 phut tuy toc do mang)..." -ForegroundColor Cyan
            New-Item -ItemType Directory -Force -Path (Split-Path $targetDir -Parent) | Out-Null
            
            git clone --depth 1 -b stable https://github.com/flutter/flutter.git $targetDir
            
            Write-Host "`nDang them vao PATH..." -ForegroundColor Cyan
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($currentPath -notlike "*$targetDir\bin*") {
                [Environment]::SetEnvironmentVariable("Path", "$currentPath;$targetDir\bin", "User")
                $env:Path += ";$targetDir\bin"
            }
            
            Write-Host "[HOAN TAT] Cai dat Flutter thanh cong!" -ForegroundColor Green
            Write-Host "Dang khoi tao Flutter lan dau (flutter doctor)..." -ForegroundColor Cyan
            & "$targetDir\bin\flutter.bat" doctor
        } else {
            Write-Host "`nHuong dan tai thu cong:" -ForegroundColor Cyan
            Write-Host "1. Vao https://docs.flutter.dev/get-started/install/windows/mobile" -ForegroundColor White
            Write-Host "2. Bam tai file zip 'flutter_windows_x.x.x-stable.zip'" -ForegroundColor White
            Write-Host "3. Giai nen vao thu muc C:\src\flutter" -ForegroundColor White
            Write-Host "4. Them C:\src\flutter\bin vao bien moi truong PATH." -ForegroundColor White
        }
    }
}

Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "     HUONG DAN DONG GOI & CHAY DU AN NOTE NTT     " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "1. Cai dat goi thu vien : flutter pub get" -ForegroundColor White
Write-Host "2. Chay thu tren Android : flutter run -d android" -ForegroundColor White
Write-Host "3. Chay tren Windows    : flutter run -d windows" -ForegroundColor White
Write-Host "4. Dong goi APK Release : flutter build apk --release" -ForegroundColor White
