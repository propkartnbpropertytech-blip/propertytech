param(
    [Parameter(Mandatory=$true)]
    [string]$NewVersion,

    [Parameter(Mandatory=$false)]
    [int]$BuildNumber = 0,

    [Parameter(Mandatory=$false)]
    [string]$Message = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Dynamically locate workspace root and frontend directory
if (Test-Path (Join-Path $scriptDir "frontend\pubspec.yaml")) {
    $rootDir = $scriptDir
    $feDir = Join-Path $rootDir "frontend"
} elseif (Test-Path (Join-Path (Split-Path -Parent $scriptDir) "pubspec.yaml")) {
    $feDir = Split-Path -Parent $scriptDir
    $rootDir = Split-Path -Parent $feDir
} elseif (Test-Path (Join-Path $scriptDir "pubspec.yaml")) {
    $feDir = $scriptDir
    $rootDir = Split-Path -Parent $feDir
} else {
    $rootDir = "C:\jay\New folder\PropKart"
    $feDir = Join-Path $rootDir "frontend"
}

$versionsDir = Join-Path $rootDir "Versions"
$archivesDir = Join-Path $versionsDir "archives"

# 1. Validate version format (e.g. 2.2.0)
if ($NewVersion -notmatch "^\d+\.\d+\.\d+$") {
    Write-Error "Invalid version format '$NewVersion'. Expected format: X.Y.Z (e.g., 2.2.0)"
    exit 1
}

# 2. Read current version from pubspec.yaml
$pubspecPath = Join-Path $feDir "pubspec.yaml"
$pubspecContent = Get-Content -Path $pubspecPath -Raw
$currentVerMatch = [regex]::Match($pubspecContent, "version:\s*([^\+\r\n]+)(?:\+(\d+))?")
if (-not $currentVerMatch.Success) {
    Write-Error "Could not find 'version:' line in $pubspecPath"
    exit 1
}
$currentVer = $currentVerMatch.Groups[1].Value.Trim()
$currentBuild = if ($currentVerMatch.Groups[2].Success) { [int]$currentVerMatch.Groups[2].Value.Trim() } else { 1 }

if ($BuildNumber -eq 0) {
    $BuildNumber = $currentBuild + 1
}

$newFull = "$NewVersion+$BuildNumber"

Write-Host "=================================================="
Write-Host "PropKart Version Transition"
Write-Host "Current Version: $currentVer (Build $currentBuild)"
Write-Host "New Version:     $NewVersion (Build $BuildNumber)"
Write-Host "=================================================="

# 3. STEP 1: Immediately take a backup of the current/previous version into Versions/
Write-Host "[STEP 1/4] Taking full backup of current version $currentVer..."
$backupScript = if (Test-Path (Join-Path $rootDir "backup_version.ps1")) {
    Join-Path $rootDir "backup_version.ps1"
} else {
    Join-Path $feDir "tool\backup_version.ps1"
}
& powershell.exe -ExecutionPolicy Bypass -File $backupScript -BackupCurrent -Force

# 4. STEP 2: Update pubspec.yaml
Write-Host "[STEP 2/4] Updating pubspec.yaml to version: $newFull..."
$updatedPubspec = [regex]::Replace($pubspecContent, "version:\s*[^\r\n]+", "version: $newFull")
Set-Content -Path $pubspecPath -Value $updatedPubspec -Encoding UTF8

# 5. STEP 3: Update config_service.dart if present
$configServicePath = Join-Path $feDir "lib\modules\config\services\config_service.dart"
if (Test-Path $configServicePath) {
    Write-Host "[STEP 3/4] Updating config_service.dart maxVersion to $NewVersion..."
    $configContent = Get-Content -Path $configServicePath -Raw
    $updatedConfig = [regex]::Replace($configContent, "max_version'\]\s*\?\?\s*'[^']+'", "max_version'] ?? '$NewVersion'")
    Set-Content -Path $configServicePath -Value $updatedConfig -Encoding UTF8
}

# 6. STEP 4: Update VERSION_CATALOG.md
$catalogPath = Join-Path $versionsDir "VERSION_CATALOG.md"
if (Test-Path $catalogPath) {
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $msgStr = if ($Message -ne "") { $Message } else { "Bumped version to $newFull" }
    $catalogEntry = "| **+** | `$newFull` | [`$NewVersion`](file:///C:/jay/New%20folder/PropKart/Versions/$NewVersion) | `PropKart_v$NewVersion.zip` | $dateStr | `Working` | Active | $msgStr |`n"
    Add-Content -Path $catalogPath -Value $catalogEntry -Encoding UTF8
}

Write-Host "=================================================="
Write-Host "SUCCESS: Previous version $currentVer is securely backed up in Versions\$currentVer"
Write-Host "New version $newFull is now active in pubspec.yaml!"
Write-Host "=================================================="
