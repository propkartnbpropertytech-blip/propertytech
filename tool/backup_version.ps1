param(
    [switch]$Force,
    [switch]$BackupCurrent
)

$ErrorActionPreference = "Stop"
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

$beDir = Join-Path $rootDir "backend"
$versionsDir = Join-Path $rootDir "Versions"
$archivesDir = Join-Path $versionsDir "archives"

if (-not (Test-Path $versionsDir)) {
    New-Item -ItemType Directory -Path $versionsDir -Force | Out-Null
}
if (-not (Test-Path $archivesDir)) {
    New-Item -ItemType Directory -Path $archivesDir -Force | Out-Null
}

# 1. Read current version from pubspec.yaml
$pubspecPath = Join-Path $feDir "pubspec.yaml"
$pubspecContent = Get-Content -Path $pubspecPath -Raw
$currentVerMatch = [regex]::Match($pubspecContent, "version:\s*([^\+\r\n]+)(?:\+(\d+))?")
if (-not $currentVerMatch.Success) {
    Write-Error "Could not find 'version:' line in $pubspecPath"
    exit 1
}
$currentVer = $currentVerMatch.Groups[1].Value.Trim()
$currentBuild = if ($currentVerMatch.Groups[2].Success) { $currentVerMatch.Groups[2].Value.Trim() } else { "1" }
$currentFull = "$currentVer+$currentBuild"

Write-Host "=================================================="
Write-Host "PropKart Version Manager"
Write-Host "Current Active Version: $currentFull"
Write-Host "=================================================="

# Function to export a version snapshot
function Export-VersionSnapshot {
    param(
        [string]$Ver,
        [string]$Build,
        [string]$CommitHash,
        [string]$Date,
        [string]$Author,
        [string]$Msg
    )

    $targetDir = Join-Path $versionsDir $Ver
    $zipPath = Join-Path $archivesDir ("PropKart_v" + $Ver + ".zip")

    if ((Test-Path $targetDir) -and (-not $Force)) {
        Write-Host "  -> Version $Ver is already backed up in Versions\$Ver."
        return
    }

    Write-Host "  -> Backing up previous version $Ver (Commit $CommitHash)..."
    if (Test-Path $targetDir) {
        Remove-Item -Recurse -Force $targetDir
    }
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

    # Extract Flutter frontend code
    cmd.exe /c "git -C `"$feDir`" archive $CommitHash | tar -x -C `"$targetDir`""

    # If 2.1.0 or later, also bundle backend if backend exists
    try {
        $vObj = [System.Version]::Parse($Ver)
        if ($vObj -ge [System.Version]::Parse("2.1.0") -and (Test-Path $beDir)) {
            $beTarget = Join-Path $targetDir "backend"
            New-Item -ItemType Directory -Path $beTarget -Force | Out-Null
            cmd.exe /c "git -C `"$beDir`" archive HEAD | tar -x -C `"$beTarget`""
        }
    } catch {}

    # Generate standalone .zip archive
    cmd.exe /c "git -C `"$feDir`" archive --format=zip -o `"$zipPath`" $CommitHash"

    # Write VERSION_INFO.md inside the version folder
    $info = @(
        "# PropKart Version $Build",
        "",
        "- **Version:** $Ver",
        "- **Build:** $Build",
        "- **Commit:** $CommitHash",
        "- **Date:** $Date",
        "- **Author:** $Author",
        "- **Release Note:** $Msg",
        "",
        "---",
        "*Clean snapshot backed up automatically by PropKart Version Manager.*"
    )
    $info | Set-Content -Path (Join-Path $targetDir "VERSION_INFO.md") -Encoding UTF8
    Write-Host "  [SUCCESS] Backed up Version $Ver into Versions\$Ver"
}

# 2. Fast scan: inspect all commits touching pubspec.yaml
Write-Host "Scanning Git history for version releases..."
$pubCommits = git -C "$feDir" log --all --reverse --format="%H %ad %an %s" --date=short -- pubspec.yaml

$parsedList = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($line in $pubCommits) {
    $parts = $line -split " ", 4
    if ($parts.Length -ge 4) {
        $hash = $parts[0]
        $date = $parts[1]
        $author = $parts[2]
        $subject = $parts[3]

        $content = git -C "$feDir" show "$($hash):pubspec.yaml" 2>$null
        if ($content) {
            $m = [regex]::Match($content, "version:\s*([^\+\r\n]+)(?:\+(\d+))?")
            if ($m.Success) {
                $vStr = $m.Groups[1].Value.Trim()
                $bStr = if ($m.Groups[2].Success) { $m.Groups[2].Value.Trim() } else { "1" }
                $parsedList.Add([PSCustomObject]@{
                    Commit = $hash
                    Ver = $vStr
                    Build = "$vStr+$bStr"
                    Date = $date
                    Author = $author
                    Subject = $subject
                })
            }
        }
    }
}

$grouped = $parsedList | Group-Object Ver
foreach ($g in $grouped) {
    $verName = $g.Name
    $lastItem = $g.Group[-1]

    # Back up any version that is not the active working version, or if Force is passed
    if ($verName -ne $currentVer -or $BackupCurrent) {
        Export-VersionSnapshot -Ver $verName `
                              -Build $lastItem.Build `
                              -CommitHash $lastItem.Commit `
                              -Date $lastItem.Date `
                              -Author $lastItem.Author `
                              -Msg $lastItem.Subject
    }
}

Write-Host "Version check complete. All previous versions are secured in Versions\."
