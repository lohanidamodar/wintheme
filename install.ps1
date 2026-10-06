#Requires -Version 5.1
# Applies the Minimal Dark theme for the current user. Safe to re-run, e.g. to change the accent.
#   .\install.ps1                     pick an accent from a menu
#   .\install.ps1 -Accent amber       rose | terracotta | amber | sand | #RRGGBB
#   .\install.ps1 -Admin              also apply the admin-only extras (UAC prompt)
param([string]$Accent, [switch]$Admin)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\settings.ps1"
Assert-InteractiveUser

$backupFile  = "$PSScriptRoot\backup.json"
$backupTheme = "$PSScriptRoot\backup-theme.theme"
$wallDir     = "$PSScriptRoot\wallpapers"
$themeFile   = "$PSScriptRoot\MinimalDark.theme"
$themesKey   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes'
$skipped     = @()

# 0. Accent
if (-not $Accent) {
    $esc = [char]27
    Write-Host "Pick an accent colour:"
    $i = 0
    foreach ($name in $Accents.Keys) {
        $c = Get-AccentColors $Accents[$name]; $i++
        Write-Host ("  {0}. $esc[48;2;{1};{2};{3}m      $esc[0m  {4,-11} {5}" -f $i, $c.R, $c.G, $c.B, $name, $Accents[$name])
    }
    $answer = Read-Host "Number, name or #RRGGBB [1]"
    $Accent = if (-not $answer) { $DefaultAccent } elseif ($answer -match '^\d+$') { @($Accents.Keys)[[int]$answer - 1] } else { $answer }
}
$hex = Resolve-Accent $Accent
$colors = Get-AccentColors $hex
$Settings = Get-Settings $hex
Write-Host "Accent: $hex"

# 1. Backup - the first run records everything; later runs only add settings not yet recorded
$backup = if (Test-Path $backupFile) { Get-Content $backupFile -Raw | ConvertFrom-Json } else { $null }
if (-not $backup) {
    $prevTheme = (Get-ItemProperty $themesKey).CurrentTheme
    if ($prevTheme -and (Test-Path $prevTheme)) { Copy-Item $prevTheme $backupTheme -Force }
    $backup = [pscustomobject][ordered]@{
        Created       = (Get-Date).ToString('s')
        PreviousTheme = $prevTheme
        Wallpaper     = (Get-ItemProperty 'HKCU:\Control Panel\Desktop').WallPaper
        Values        = @()
    }
    Write-Host "Backing up current settings to backup.json"
}
if (-not ($backup.PSObject.Properties.Name -contains 'LockScreenImage')) {
    $backup | Add-Member LockScreenImage (Get-LockScreenImage)
}
$backup.Values = Get-BackupEntries $Settings $backup.Values
ConvertTo-Json -InputObject $backup -Depth 5 | Set-Content $backupFile -Encoding UTF8

# 2. Wallpapers
New-Item -ItemType Directory -Force $wallDir | Out-Null
$list = Get-Content "$PSScriptRoot\wallpapers.json" -Raw | ConvertFrom-Json
foreach ($p in $list.PSObject.Properties) {
    $dest = Join-Path $wallDir ([IO.Path]::GetFileName($p.Value))
    if (Test-Path $dest) { continue }
    try {
        Write-Host "Downloading $($p.Name)..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $p.Value -OutFile "$dest.part" -UseBasicParsing
        Move-Item "$dest.part" $dest -Force
    } catch {
        Remove-Item "$dest.part" -ErrorAction SilentlyContinue
        Write-Warning "Could not download $($p.Name): $($_.Exception.Message)"
        $skipped += "wallpaper $($p.Name) (download failed)"
    }
}
$images = Get-ChildItem $wallDir -File | Where-Object Extension -in '.jpg', '.png'
if (-not $images) { throw "No wallpapers available in $wallDir - aborting before any change." }

# 3. Theme file, built on top of the previous theme so cursors, sounds and screensaver stay as they are
$base = if (Test-Path $backupTheme) { Get-Content $backupTheme } else { @() }
$sections = [ordered]@{}; $current = $null
foreach ($line in $base) {
    if ($line -match '^\s*\[(.+)\]\s*$') { $current = $Matches[1]; if (-not $sections.Contains($current)) { $sections[$current] = [ordered]@{} } }
    elseif ($current -and $line -match '^\s*([^;=][^=]*?)\s*=(.*)$') { $sections[$current][$Matches[1]] = $Matches[2] }
}
function Set-Ini($section, $values) {
    if (-not $sections.Contains($section)) { $sections[$section] = [ordered]@{} }
    foreach ($k in $values.Keys) { $sections[$section][$k] = $values[$k] }
}
Set-Ini 'Theme' ([ordered]@{ DisplayName = 'Minimal Dark'; ThemeId = '{6D1F3A52-8C4E-4B7A-9E21-C27C88D0A5E1}' })
Set-Ini 'boot' ([ordered]@{ 'SCRNSAVE.EXE' = (Get-ItemProperty 'HKCU:\Control Panel\Desktop').'SCRNSAVE.EXE' })
Set-Ini 'Control Panel\Desktop' ([ordered]@{ Wallpaper = $images[0].FullName; TileWallpaper = '0'; WallpaperStyle = '10'; Pattern = '' })
Set-Ini 'VisualStyles' ([ordered]@{
    Path = '%SystemRoot%\resources\themes\Aero\Aero.msstyles'; ColorStyle = 'NormalColor'; Size = 'NormalSize'
    AutoColorization = '0'; ColorizationColor = ('0X{0:X8}' -f $colors.Argb); SystemMode = 'Dark'; AppMode = 'Dark'; VisualStyleVersion = '10'
})
Set-Ini 'Slideshow' ([ordered]@{ Interval = '1800000'; Shuffle = '1'; ImagesRootPath = $wallDir })
Set-Ini 'MasterThemeSelector' ([ordered]@{ MTSM = 'RJSPBS' })
$sections.Remove('Control Panel\Colors')   # let dark mode drive system colours
$out = foreach ($sec in $sections.Keys) {
    "[$sec]"; foreach ($k in $sections[$sec].Keys) { "$k=$($sections[$sec][$k])" }; ''
}
$out | Set-Content $themeFile -Encoding Unicode
Write-Host "Applying theme..."
if (-not (Invoke-Theme $themeFile)) {
    Write-Warning "Windows did not confirm the theme; open MinimalDark.theme manually to apply the wallpaper slideshow."
    $skipped += "theme/slideshow (not confirmed)"
}

# 4. Registry values (after the theme, so the theme can't override them)
$skipped += @(Set-Values $Settings)

# 5. Lock screen: same wallpapers, a new one at every sign-in and unlock
try {
    & "$PSScriptRoot\lockscreen.ps1"
    $cls = Get-CimClass -Namespace Root/Microsoft/Windows/TaskScheduler -ClassName MSFT_TaskSessionStateChangeTrigger
    $user = "$env:USERDOMAIN\$env:USERNAME"
    $triggers = @(
        New-ScheduledTaskTrigger -AtLogOn -User $user
        New-CimInstance -CimClass $cls -ClientOnly -Property @{ StateChange = 8; UserId = $user }   # 8 = session unlock
    )
    $action = New-ScheduledTaskAction -Execute 'conhost.exe' -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\lockscreen.ps1`""
    $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
    Register-ScheduledTask -TaskName $LockTaskName -Action $action -Trigger $triggers -Principal $principal -Settings $taskSettings -Force | Out-Null
} catch {
    Write-Warning "Lock screen not set: $($_.Exception.Message)"
    $skipped += "lock screen ($($_.Exception.Message))"
}

# 6. Admin-only extras
if ($Admin) {
    Write-Host "Requesting administrator rights for the extras..."
    & "$PSScriptRoot\admin.ps1"
    if ($LASTEXITCODE -ne 0) { $skipped += "admin extras (cancelled or failed)" }
}

# 7. Restart Explorer
Restart-Explorer

# 8. Summary
$ok = @($Settings | Where-Object { Test-SettingValue $_ (Get-RegValue $_.Path $_.Name) }).Count
Write-Host ""
Write-Host "Minimal Dark applied: accent $hex, $ok/$($Settings.Count) settings, $($images.Count) wallpapers on desktop and lock screen."
if ($skipped) { Write-Host "Skipped:"; $skipped | ForEach-Object { Write-Host "  - $_" } }
Write-Host "Change accent: .\install.ps1 -Accent <name>   Undo: .\uninstall.ps1"
