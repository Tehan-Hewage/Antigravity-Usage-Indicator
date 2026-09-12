<#
.SYNOPSIS
    Builds, optimizes, packages, and archives the Antigravity Usage Indicator Windows release.

.DESCRIPTION
    Runs tests and static analysis, executes `flutter build windows --release`,
    assembles a clean standalone distribution folder with all necessary DLLs,
    assets, and background sync scripts, and creates a portable zip archive.

.EXAMPLE
    .\scripts\build_release.ps1
#>

[CmdletBinding()]
param (
    [switch]$SkipTests,
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $ProjectRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Antigravity Usage Indicator - Production Release Pipeline  " -ForegroundColor Cyan
Write-Host "  Target: Windows x64 Release (v$Version)                    " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Step 1: Verification (Analysis and Tests)
if (-not $SkipTests) {
    Write-Host "`n[1/5] Running static analysis..." -ForegroundColor Yellow
    & flutter analyze
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Static analysis failed with exit code $LASTEXITCODE. Aborting build."
        exit $LASTEXITCODE
    }
    Write-Host "Analysis passed cleanly!" -ForegroundColor Green

    Write-Host "`n[2/5] Running automated tests..." -ForegroundColor Yellow
    & flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Unit/Widget tests failed with exit code $LASTEXITCODE. Aborting build."
        exit $LASTEXITCODE
    }
    Write-Host "All tests passed cleanly!" -ForegroundColor Green
} else {
    Write-Host "`n[1/5] Skipping tests and analysis (--SkipTests)." -ForegroundColor DarkGray
}

# Step 2: Flutter Release Build
Write-Host "`n[3/5] Building Windows Release binary..." -ForegroundColor Yellow
& flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter build failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}
Write-Host "Release build succeeded!" -ForegroundColor Green

# Step 3: Package Assembly
Write-Host "`n[4/5] Assembling standalone distribution package..." -ForegroundColor Yellow

$ReleaseSource = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
if (-not (Test-Path $ReleaseSource)) {
    # Some Flutter versions output to x64 subdirectory, verify path
    $AltSource = Join-Path $ProjectRoot "build\windows\runner\Release"
    if (Test-Path $AltSource) {
        $ReleaseSource = $AltSource
    } else {
        Write-Error "Could not locate compiled release output at $ReleaseSource"
        exit 1
    }
}

$DistDir = Join-Path $ProjectRoot "dist"
$PackageDirName = "AntigravityUsageIndicator-v$Version-windows-x64"
$PackageDir = Join-Path $DistDir $PackageDirName
$ZipFile = Join-Path $DistDir "$PackageDirName.zip"

# Stop running instance if open so files are not locked
Stop-Process -Name "AntigravityUsageIndicator" -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path $PackageDir) {
    Remove-Item -Recurse -Force $PackageDir
}
if (Test-Path $ZipFile) {
    Remove-Item -Force $ZipFile
}

New-Item -ItemType Directory -Force -Path $PackageDir | Out-Null

# Copy binary, DLLs, and data directory
Copy-Item -Path "$ReleaseSource\*" -Destination $PackageDir -Recurse -Force

# Copy bridge and scripts directories for local sync
$BridgeTarget = Join-Path $PackageDir "bridge"
$ScriptsTarget = Join-Path $PackageDir "scripts"

New-Item -ItemType Directory -Force -Path $BridgeTarget | Out-Null
New-Item -ItemType Directory -Force -Path $ScriptsTarget | Out-Null

Copy-Item -Path (Join-Path $ProjectRoot "bridge\quota_bridge.ps1") -Destination $BridgeTarget -Force
Copy-Item -Path (Join-Path $ProjectRoot "scripts\sync_daemon.ps1") -Destination $ScriptsTarget -Force
Copy-Item -Path (Join-Path $ProjectRoot "scripts\register_scheduled_task.ps1") -Destination $ScriptsTarget -Force

# Copy icon assets
$AssetsTarget = Join-Path $PackageDir "assets\icons"
New-Item -ItemType Directory -Force -Path $AssetsTarget | Out-Null
Copy-Item -Path (Join-Path $ProjectRoot "assets\icons\*") -Destination $AssetsTarget -Force

# Generate Distribution README
$ReadmeContent = @"
========================================================================
   Antigravity Usage Indicator (v$Version - Windows x64 Standalone)
   A sleek floating dynamic notch for Gemini & Claude quota monitoring
========================================================================

QUICK START:
1. Double-click `antigravity_usage_indicator.exe` to launch.
2. The indicator will appear docked smoothly at the top center of your screen.
3. The system tray icon (glowing sparkle) appears in your Windows taskbar notification area.

INTERACTION & CONTROLS:
- Click the notch: Expands to show details (weekly limit, 5-hour limit, reset time, refresh).
- Drag the notch: Move anywhere on your desktop. When near the top center, it magnetically snaps into place.
- Right-click anywhere on the notch or tray icon:
  * Open Settings (Display mode, presets, always-on-top, auto-launch)
  * Sync Quota Now
  * Reset Position to Top Center
  * Hide / Show
  * Exit

BACKGROUND AUTO-SYNC:
- Automatically syncs with your Google Antigravity session every 3 minutes.
- When you click 'Refresh' in the expanded card, an instant live sync executes silently.
- To run scheduled sync independently of the UI:
  Run PowerShell: .\scripts\register_scheduled_task.ps1

SYSTEM REQUIREMENTS:
- Windows 10 (version 1809+) or Windows 11 (64-bit)
- No administrative privileges required.
========================================================================
"@

Set-Content -Path (Join-Path $PackageDir "README.txt") -Value $ReadmeContent -Encoding UTF8

Write-Host "Package assembled at: $PackageDir" -ForegroundColor Green

# Step 4: Zip Archive Creation
Write-Host "`n[5/5] Creating portable ZIP archive..." -ForegroundColor Yellow
Compress-Archive -Path "$PackageDir\*" -DestinationPath $ZipFile -CompressionLevel Optimal

$ZipSizeMb = [math]::Round(((Get-Item $ZipFile).Length / 1MB), 2)
Write-Host "Created archive: $ZipFile ($ZipSizeMb MB)" -ForegroundColor Green

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  BUILD COMPLETE - PRODUCTION READY!                         " -ForegroundColor Cyan
Write-Host "  Binary Folder: $PackageDir                                 " -ForegroundColor Cyan
Write-Host "  Portable ZIP:  $ZipFile                                    " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
