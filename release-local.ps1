<#
.SYNOPSIS
  One-Click Local Release Builder & GitHub Publisher for PropKart CRM
.DESCRIPTION
  Builds Android APK and Windows Desktop locally, then automatically uploads
  the release binaries to GitHub Releases using GitHub CLI (gh).
#>

$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "🚀 PropKart CRM — Local Multi-Platform Release Builder" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# 1. Determine Version from pubspec.yaml
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "pubspec.yaml not found in current directory."
    exit 1
}

$rawVersionLine = Get-Content "pubspec.yaml" | Select-String -Pattern "^version:\s*(.+)$"
if ($rawVersionLine -match "^version:\s*([^\s+]+)") {
    $cleanVersion = $matches[1]
    $tag = "v$cleanVersion"
} else {
    $cleanVersion = "1.1.2"
    $tag = "v1.1.2"
}

Write-Host "📦 Target Version: $cleanVersion ($tag)" -ForegroundColor Yellow

# 2. Get Flutter dependencies
Write-Host "`n[1/5] 📥 Running flutter pub get..." -ForegroundColor Green
flutter pub get

# 3. Build Android Release APK
Write-Host "`n[2/5] 📱 Building Android Release APK..." -ForegroundColor Green
flutter build apk --release --dart-define=APP_ENV=production
if (Test-Path "build\app\outputs\flutter-apk\app-release.apk") {
    Copy-Item "build\app\outputs\flutter-apk\app-release.apk" -Destination "PropKart-release.apk" -Force
    Write-Host "✅ Android APK built: PropKart-release.apk" -ForegroundColor Green
} else {
    Write-Error "Failed to locate Android APK output."
}

# 4. Build Windows Desktop Release
Write-Host "`n[3/5] 🖥️ Building Windows Desktop Release..." -ForegroundColor Green
flutter build windows --release --dart-define=APP_ENV=production
$winPath = if (Test-Path "build\windows\x64\runner\Release") { "build\windows\x64\runner\Release\*" } else { "build\windows\runner\Release\*" }
Compress-Archive -Path $winPath -DestinationPath "PropKart-Windows-x64.zip" -Force
Write-Host "✅ Windows Desktop bundle zipped: PropKart-Windows-x64.zip" -ForegroundColor Green

# 5. Generate version.json
Write-Host "`n[4/5] 📝 Generating version registry..." -ForegroundColor Green
$nowIso = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$versionRegistry = @"
{
  "version": "$cleanVersion",
  "tag": "$tag",
  "published_at": "$nowIso",
  "apk_url": "https://github.com/propkartnbpropertytech-blip/propertytech/releases/latest/download/PropKart-release.apk",
  "windows_url": "https://github.com/propkartnbpropertytech-blip/propertytech/releases/latest/download/PropKart-Windows-x64.zip",
  "linux_url": "https://github.com/propkartnbpropertytech-blip/propertytech/releases/latest/download/PropKart-linux-x86_64.tar.gz",
  "web_url": "https://propkart.nbpropertytech.com"
}
"@
Set-Content -Path "version.json" -Value $versionRegistry
Write-Host "✅ version.json created." -ForegroundColor Green

# 6. Upload directly to GitHub Releases
Write-Host "`n[5/5] 🌐 Publishing assets to GitHub Release $tag..." -ForegroundColor Green
$releaseExists = gh release view $tag 2>$null
if ($LASTEXITCODE -eq 0) {
    gh release upload $tag PropKart-release.apk PropKart-Windows-x64.zip version.json --clobber
} else {
    gh release create $tag PropKart-release.apk PropKart-Windows-x64.zip version.json --title "PropKart CRM $tag" --notes "PropKart CRM $tag Production Release"
}

Write-Host "`n🎉 Successfully published PropKart CRM $tag to GitHub Releases!" -ForegroundColor Cyan
Write-Host "🌐 Live link: https://github.com/propkartnbpropertytech-blip/propertytech/releases/tag/$tag" -ForegroundColor Cyan
