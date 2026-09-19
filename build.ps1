<#
.SYNOPSIS
    Builds the pymap release bundle for Windows (pymap.exe + engine.exe).
.DESCRIPTION
    1. Freezes engine/main.py into engine.exe using PyInstaller.
    2. Builds the Rust CLI binary (pymap.exe) using Cargo with the MSVC target.
    3. Packages both executables and documentation into dist/pymap-win64/.
#>

[CmdletBinding()]
param(
    [string]$Target = "x86_64-pc-windows-msvc",
    [switch]$SkipPythonEngine,
    [switch]$Zip
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Building pymap Windows Release Bundle   " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$DistDir = Join-Path $ProjectRoot "dist"
$BundleDir = Join-Path $DistDir "pymap-win64"

if (Test-Path $BundleDir) {
    Remove-Item -Recurse -Force $BundleDir
}
New-Item -ItemType Directory -Path $BundleDir -Force | Out-Null

# 1. Build Python Engine with PyInstaller
if (-not $SkipPythonEngine) {
    Write-Host "`n[1/3] Freezing Python Engine (engine.exe)..." -ForegroundColor Yellow

    # Verify PyInstaller is installed
    $pyinstallerCheck = Get-Command pyinstaller -ErrorAction SilentlyContinue
    if (-not $pyinstallerCheck) {
        Write-Warning "PyInstaller not found in PATH."
        Write-Host "Installing PyInstaller via pip..." -ForegroundColor DarkYellow
        python -m pip install -r (Join-Path $ProjectRoot "engine\requirements.txt")
    }

    $EngineScript = Join-Path $ProjectRoot "engine\main.py"
    python -m PyInstaller --onefile --name "engine" --distpath (Join-Path $DistDir "engine_build") --workpath (Join-Path $DistDir "build_temp") --specpath (Join-Path $DistDir "spec") $EngineScript

    $BuiltEngineExe = Join-Path $DistDir "engine_build\engine.exe"
    if (Test-Path $BuiltEngineExe) {
        Copy-Item $BuiltEngineExe (Join-Path $BundleDir "engine.exe")
        Write-Host "  -> Successfully packaged engine.exe" -ForegroundColor Green
    } else {
        throw "Failed to locate generated engine.exe at $BuiltEngineExe"
    }
} else {
    Write-Host "`n[1/3] Skipping Python Engine freeze (-SkipPythonEngine)." -ForegroundColor DarkGray
    $BuiltEngineExe = Join-Path $DistDir "engine_build\engine.exe"
    if (Test-Path $BuiltEngineExe) {
        Copy-Item $BuiltEngineExe (Join-Path $BundleDir "engine.exe")
        Write-Host "  -> Copied existing engine.exe from previous build" -ForegroundColor Green
    }
}

# 2. Build Rust CLI with Cargo
Write-Host "`n[2/3] Building Rust CLI (pymap.exe)..." -ForegroundColor Yellow
$cargoCheck = Get-Command cargo -ErrorAction SilentlyContinue
if (-not $cargoCheck) {
    $cargoBin = Join-Path $env:USERPROFILE ".cargo\bin"
    if (Test-Path (Join-Path $cargoBin "cargo.exe")) {
        $env:PATH = "$cargoBin;$env:PATH"
        $cargoCheck = Get-Command cargo -ErrorAction SilentlyContinue
    }
}

if (-not $cargoCheck) {
    Write-Warning "Cargo is not found in PATH. Please install Rust from https://rustup.rs/"
    Write-Warning "Skipping Rust build step. Please run 'cargo build --release --target $Target' once Rust is installed."
} else {
    cargo build --release --target $Target
    $BuiltRustExe = Join-Path $ProjectRoot "target\$Target\release\pymap.exe"
    if (-not (Test-Path $BuiltRustExe)) {
        # Fallback to standard release path if default target
        $BuiltRustExe = Join-Path $ProjectRoot "target\release\pymap.exe"
    }

    if (Test-Path $BuiltRustExe) {
        Copy-Item $BuiltRustExe (Join-Path $BundleDir "pymap.exe")
        Write-Host "  -> Successfully compiled pymap.exe" -ForegroundColor Green
    } else {
        throw "Failed to locate generated pymap.exe at $BuiltRustExe"
    }
}

# 3. Copy Docs & Metadata
Write-Host "`n[3/3] Assembling distribution bundle..." -ForegroundColor Yellow
if (Test-Path (Join-Path $ProjectRoot "README.md")) {
    Copy-Item (Join-Path $ProjectRoot "README.md") $BundleDir
}
if (Test-Path (Join-Path $ProjectRoot "LICENSE")) {
    Copy-Item (Join-Path $ProjectRoot "LICENSE") $BundleDir
}

if ($Zip) {
    $ZipPath = Join-Path $DistDir "pymap-win64.zip"
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path "$BundleDir\*" -DestinationPath $ZipPath
    Write-Host "  -> Created archive: $ZipPath" -ForegroundColor Green
}

Write-Host "`nBundle ready at: $BundleDir" -ForegroundColor Green
Write-Host "Contents:"
Get-ChildItem $BundleDir | Select-Object Name, Length | Format-Table -AutoSize
