# One-line installer for Minimal Dark. Downloads the latest version to
# %LOCALAPPDATA%\MinimalDark (no git needed) and runs install.ps1 or uninstall.ps1.
#
#   irm https://raw.githubusercontent.com/lohanidamodar/wintheme/master/get.ps1 | iex
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/lohanidamodar/wintheme/master/get.ps1))) -Accent amber -Admin
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/lohanidamodar/wintheme/master/get.ps1))) -Uninstall
param(
    [string]$Accent,
    [switch]$Admin,
    [switch]$Uninstall,
    [switch]$RemoveWallpapers
)
$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'MinimalDark'

function Invoke-Script($file, $params) {
    # A child process with -ExecutionPolicy Bypass, so the system policy doesn't block the scripts.
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir $file) @params
}

if ($Uninstall) {
    if (-not (Test-Path "$dir\uninstall.ps1")) { Write-Host "Minimal Dark is not installed in $dir."; return }
    Invoke-Script 'uninstall.ps1' $(if ($RemoveWallpapers) { @('-RemoveWallpapers') } else { @() })
    return
}

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$tmp = Join-Path $env:TEMP "MinimalDark-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Force $tmp | Out-Null
try {
    Write-Host "Downloading Minimal Dark..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest 'https://github.com/lohanidamodar/wintheme/archive/refs/heads/master.zip' -OutFile "$tmp\wintheme.zip" -UseBasicParsing
    Expand-Archive "$tmp\wintheme.zip" $tmp -Force
    $src = Get-ChildItem $tmp -Directory | Select-Object -First 1
    New-Item -ItemType Directory -Force $dir | Out-Null
    # Updates the scripts in place; wallpapers and backups in $dir are left alone
    Copy-Item "$($src.FullName)\*" $dir -Recurse -Force
    Get-ChildItem $dir -Recurse -File | Unblock-File
} finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

$params = @()
if ($Accent) { $params += '-Accent', $Accent }
if ($Admin)  { $params += '-Admin' }
Invoke-Script 'install.ps1' $params
Write-Host "Installed to $dir"
