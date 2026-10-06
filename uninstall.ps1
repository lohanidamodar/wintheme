#Requires -Version 5.1
# Restores everything install.ps1 (and admin.ps1) changed, from the backups.
param([switch]$RemoveWallpapers)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\settings.ps1"
Assert-InteractiveUser

$backupFile  = "$PSScriptRoot\backup.json"
$backupTheme = "$PSScriptRoot\backup-theme.theme"
if (-not (Test-Path $backupFile)) { throw "No backup.json found - nothing to restore." }
$backup = Get-Content $backupFile -Raw | ConvertFrom-Json
$failed = @()

# 1. Admin extras, if they were applied
if (Test-Path "$PSScriptRoot\backup-admin.json") {
    Write-Host "Requesting administrator rights to restore the admin extras..."
    & "$PSScriptRoot\admin.ps1" -Restore
    if ($LASTEXITCODE -ne 0) { $failed += 'admin extras (run .\admin.ps1 -Restore)' }
}

# 2. Lock screen
Unregister-ScheduledTask -TaskName $LockTaskName -Confirm:$false -ErrorAction SilentlyContinue
if ($backup.LockScreenImage -and (Test-Path $backup.LockScreenImage)) {
    try { Set-LockScreenImage $backup.LockScreenImage } catch { $failed += 'lock screen image' }
}

# 3. Windows Terminal
if ($backup.PSObject.Properties.Name -contains 'Terminal') {
    try { $failed += @(Uninstall-Terminal $backup.Terminal) } catch { $failed += "Windows Terminal ($($_.Exception.Message))" }
}

# 4. Previous theme first, so the restored values below win
if (Test-Path $backupTheme) {
    Write-Host "Restoring previous theme..."
    if (-not (Invoke-Theme $backupTheme)) { Write-Warning "Windows did not confirm the previous theme; open backup-theme.theme manually." }
} elseif ($backup.Wallpaper) {
    Set-ItemProperty 'HKCU:\Control Panel\Desktop' WallPaper $backup.Wallpaper
}

# 5. Registry values
$failed += @(Restore-Values $backup.Values)

Restart-Explorer

if ($RemoveWallpapers) { Remove-Item "$PSScriptRoot\wallpapers" -Recurse -Force -ErrorAction SilentlyContinue }
Remove-Item "$PSScriptRoot\MinimalDark.theme" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Restored settings from the backup taken $($backup.Created)."
if ($failed) { Write-Host "Not restored: $($failed -join ', ')" }
Write-Host "backup.json kept; delete it before the next install to take a fresh backup."
