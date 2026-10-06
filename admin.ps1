#Requires -Version 5.1
# Optional extras that need administrator rights: Widgets and Copilot turned off by policy,
# and no web results in Start search. Called by install.ps1 -Admin / uninstall.ps1, or run directly.
param([switch]$Restore)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\settings.ps1"

if (-not (Test-Elevated)) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Restore) { $argList += '-Restore' }
    $p = Start-Process powershell.exe -ArgumentList $argList -Verb RunAs -Wait -PassThru
    exit $p.ExitCode
}
Assert-InteractiveUser   # elevated HKCU must still be the signed-in user's

$backupFile = "$PSScriptRoot\backup-admin.json"
Start-Transcript -Path "$PSScriptRoot\admin.log" | Out-Null   # the elevated window closes, so keep a record
try {
    if ($Restore) {
        if (-not (Test-Path $backupFile)) { Write-Host "No admin backup - nothing to restore."; exit 0 }
        $failed = @(Restore-Values (Get-Content $backupFile -Raw | ConvertFrom-Json))
        Remove-Item $backupFile
        Write-Host "Admin extras restored$(if ($failed) { "; not restored: $($failed -join ', ')" })."
    } else {
        $existing = if (Test-Path $backupFile) { Get-Content $backupFile -Raw | ConvertFrom-Json } else { @() }
        ConvertTo-Json -InputObject (Get-BackupEntries $AdminSettings $existing) -Depth 4 | Set-Content $backupFile -Encoding UTF8
        $skipped = @(Set-Values $AdminSettings)
        Write-Host "Admin extras applied: $($AdminSettings.Count - $skipped.Count)/$($AdminSettings.Count)."
    }
    exit 0
} catch {
    Write-Warning $_
    Start-Sleep -Seconds 5   # keep the elevated window readable
    exit 1
}
