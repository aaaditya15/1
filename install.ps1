<#
.SYNOPSIS
    One-line installer for pymap on Windows.
.DESCRIPTION
    Downloads the latest pymap release from GitHub, installs it to %LOCALAPPDATA%\Programs\pymap,
    and safely registers the install folder in the user's PATH environment variable.
.EXAMPLE
    irm https://raw.githubusercontent.com/aaaditya15/1/main/install.ps1 | iex
#>

[CmdletBinding()]
param(
    [string]$Repo = "aaaditya15/1",
    [string]$Version = "latest",
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\pymap"
)

$ErrorActionPreference = "Stop"

Write-Host @"
===============================================
           Installing pymap for Windows
===============================================
"@ -ForegroundColor Cyan

# 1. Determine download URL
if ($Version -eq "latest") {
    $ReleaseApiUrl = "https://api.github.com/repos/$Repo/releases/latest"
    Write-Host "[*] Finding latest release for $Repo..." -ForegroundColor DarkGray
    try {
        $ReleaseData = Invoke-RestMethod -Uri $ReleaseApiUrl -Headers @{ "User-Agent" = "pymap-installer" }
        $Asset = $ReleaseData.assets | Where-Object { $_.name -like "*win64.zip" -or $_.name -like "*.zip" } | Select-Object -First 1
        if ($Asset) {
            $DownloadUrl = $Asset.browser_download_url
            $VersionTag = $ReleaseData.tag_name
        } else {
            throw "No zip asset found in latest release."
        }
    } catch {
        Write-Warning "Could not query GitHub API (rate-limit or private repo). Falling back to direct URL..."
        $DownloadUrl = "https://github.com/$Repo/releases/latest/download/pymap-win64.zip"
        $VersionTag = "latest"
    }
} else {
    $VersionTag = $Version
    $DownloadUrl = "https://github.com/$Repo/releases/download/$Version/pymap-win64.zip"
}

Write-Host "[*] Target Version: $VersionTag" -ForegroundColor Yellow
Write-Host "[*] Download URL:   $DownloadUrl" -ForegroundColor DarkGray
Write-Host "[*] Install Path:   $InstallDir" -ForegroundColor Yellow

# 2. Download release zip to temporary directory
$TempZip = Join-Path $env:TEMP "pymap-install-$([guid]::NewGuid().ToString('N')).zip"
Write-Host "`n[*] Downloading pymap bundle..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip -UseBasicParsing
} catch {
    Write-Error "Failed to download release from $DownloadUrl. Please verify the repository and release tag exist."
    exit 1
}

# 3. Extract to target directory
Write-Host "[*] Extracting files..." -ForegroundColor Cyan
if (Test-Path $InstallDir) {
    # Backup or overwrite existing installation
    Remove-Item -Recurse -Force $InstallDir
}
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force
Remove-Item -Force $TempZip -ErrorAction SilentlyContinue

# Handle nested archive root if bundle was inside a subfolder
$SubDir = Get-ChildItem -Path $InstallDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "pymap.exe") }
if ($SubDir) {
    Get-ChildItem -Path $SubDir.FullName | Move-Item -Destination $InstallDir -Force
    Remove-Item -Recurse -Force $SubDir.FullName
}

# 4. Safely add to User PATH (Registry-based to avoid 1024-char setx truncation)
Write-Host "[*] Updating User PATH environment variable..." -ForegroundColor Cyan
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$PathEntries = ($UserPath -split ";") | Where-Object { $_ -ne "" }

if ($PathEntries -notcontains $InstallDir) {
    $NewUserPath = if ([string]::IsNullOrWhiteSpace($UserPath)) { $InstallDir } else { "$UserPath;$InstallDir" }
    [Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
    Write-Host "  -> Added '$InstallDir' to User PATH." -ForegroundColor Green
} else {
    Write-Host "  -> '$InstallDir' is already in User PATH." -ForegroundColor DarkGray
}

# Update current process PATH so pymap can be tested immediately in the active session
if (($env:PATH -split ";") -notcontains $InstallDir) {
    $env:PATH = "$InstallDir;$env:PATH"
}

# 5. Verify Installation
$PymapExe = Join-Path $InstallDir "pymap.exe"
if (Test-Path $PymapExe) {
    Write-Host @"

===============================================
 [SUCCESS] pymap was successfully installed!
===============================================

Location: $InstallDir\pymap.exe

Quick Start:
  Restart your open terminal windows for PATH changes to apply,
  or run it immediately in this window:

    pymap --help
    pymap info
    pymap scan 127.0.0.1 -p 80,443

===============================================
"@ -ForegroundColor Green
} else {
    Write-Warning "Installation finished, but 'pymap.exe' was not found directly in $InstallDir."
}
