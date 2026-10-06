#Requires -Version 5.1
# Restores everything install.ps1 changed, from backup.json.
param([switch]$RemoveWallpapers)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\settings.ps1"
Assert-InteractiveUser

$backupFile  = "$PSScriptRoot\backup.json"
$backupTheme = "$PSScriptRoot\backup-theme.theme"
if (-not (Test-Path $backupFile)) { throw "No backup.json found - nothing to restore." }
$backup = Get-Content $backupFile -Raw | ConvertFrom-Json
$failed = @()

# 1. Previous theme first, so the restored values below win
if (Test-Path $backupTheme) {
    Write-Host "Restoring previous theme..."
    if (-not (Invoke-Theme $backupTheme)) { Write-Warning "Windows did not confirm the previous theme; open backup-theme.theme manually." }
} elseif ($backup.Wallpaper) {
    Set-ItemProperty 'HKCU:\Control Panel\Desktop' WallPaper $backup.Wallpaper
}

# 2. Registry values
foreach ($e in $backup.Values) {
    try {
        if ($e.Exists) {
            if (-not (Test-Path $e.Path)) { New-Item -Path $e.Path -Force | Out-Null }
            $v = if ($e.Kind -eq 'Binary') { [Convert]::FromBase64String($e.Value) } else { $e.Value }
            Set-ItemProperty -Path $e.Path -Name $e.Name -Value $v -Type $e.Kind
        } elseif (Get-Item $e.Path -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $e.Path -Name $e.Name -ErrorAction SilentlyContinue
        }
    } catch {
        $now = Get-RegValue $e.Path $e.Name
        if ($e.Exists -and $e.Kind -ne 'Binary' -and $now -eq $e.Value) { continue }   # protected but already original
        Write-Warning "Could not restore $($e.Name): $($_.Exception.Message)"
        $failed += $e.Name
    }
}

Restart-Explorer

if ($RemoveWallpapers) { Remove-Item "$PSScriptRoot\wallpapers" -Recurse -Force -ErrorAction SilentlyContinue }
Remove-Item "$PSScriptRoot\MinimalDark.theme" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Restored $($backup.Values.Count - $failed.Count)/$($backup.Values.Count) settings from backup taken $($backup.Created)."
if ($failed) { Write-Host "Not restored: $($failed -join ', ')" }
Write-Host "backup.json kept; delete it before the next install to take a fresh backup."
