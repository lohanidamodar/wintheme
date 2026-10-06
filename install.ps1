#Requires -Version 5.1
# Applies the Minimal Dark theme for the current user. Safe to re-run.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\settings.ps1"
Assert-InteractiveUser

$backupFile  = "$PSScriptRoot\backup.json"
$backupTheme = "$PSScriptRoot\backup-theme.theme"
$wallDir     = "$PSScriptRoot\wallpapers"
$themeFile   = "$PSScriptRoot\MinimalDark.theme"
$themesKey   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes'
$skipped     = @()

# 1. Backup (first run only)
if (-not (Test-Path $backupFile)) {
    $entries = foreach ($s in $Settings) {
        $key = Get-Item -Path $s.Path -ErrorAction SilentlyContinue
        $exists = $key -and ($key.GetValueNames() -contains $s.Name)
        $entry = [ordered]@{ Path = $s.Path; Name = $s.Name; Exists = [bool]$exists; Kind = $null; Value = $null }
        if ($exists) {
            $entry.Kind = $key.GetValueKind($s.Name).ToString()
            $v = $key.GetValue($s.Name, $null, 'DoNotExpandEnvironmentNames')
            $entry.Value = if ($v -is [byte[]]) { [Convert]::ToBase64String($v) } else { $v }
        }
        $entry
    }
    $prevTheme = (Get-ItemProperty $themesKey).CurrentTheme
    if ($prevTheme -and (Test-Path $prevTheme)) { Copy-Item $prevTheme $backupTheme -Force }
    [ordered]@{
        Created       = (Get-Date).ToString('s')
        PreviousTheme = $prevTheme
        Wallpaper     = (Get-ItemProperty 'HKCU:\Control Panel\Desktop').WallPaper
        Values        = @($entries)
    } | ConvertTo-Json -Depth 5 | Set-Content $backupFile -Encoding UTF8
    Write-Host "Backed up current settings to backup.json"
} else {
    Write-Host "backup.json already exists - keeping the original backup"
}

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

# 3. Theme file, built on top of the current theme so cursors, sounds and screensaver stay as they are
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
$colorHex = '0X{0:X8}' -f $argb
Set-Ini 'Theme' ([ordered]@{ DisplayName = 'Minimal Dark'; ThemeId = '{6D1F3A52-8C4E-4B7A-9E21-C27C88D0A5E1}' })
Set-Ini 'boot' ([ordered]@{ 'SCRNSAVE.EXE' = (Get-ItemProperty 'HKCU:\Control Panel\Desktop').'SCRNSAVE.EXE' })
Set-Ini 'Control Panel\Desktop' ([ordered]@{ Wallpaper = $images[0].FullName; TileWallpaper = '0'; WallpaperStyle = '10'; Pattern = '' })
Set-Ini 'VisualStyles' ([ordered]@{
    Path = '%SystemRoot%\resources\themes\Aero\Aero.msstyles'; ColorStyle = 'NormalColor'; Size = 'NormalSize'
    AutoColorization = '0'; ColorizationColor = $colorHex; SystemMode = 'Dark'; AppMode = 'Dark'; VisualStyleVersion = '10'
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
foreach ($s in $Settings) {
    try {
        if (-not (Test-Path $s.Path)) { New-Item -Path $s.Path -Force | Out-Null }
        Set-ItemProperty -Path $s.Path -Name $s.Name -Value $s.Value -Type $s.Type
    } catch {
        if (Test-SettingValue $s (Get-RegValue $s.Path $s.Name)) { continue }   # protected but already correct
        Write-Warning "Could not set $($s.Name): $($_.Exception.Message)"
        $skipped += "$($s.Name) (write blocked)"
    }
}

# 5. Restart Explorer
Restart-Explorer

# 6. Summary
$ok = @($Settings | Where-Object { Test-SettingValue $_ (Get-RegValue $_.Path $_.Name) }).Count
Write-Host ""
Write-Host "Minimal Dark applied: $ok/$($Settings.Count) settings, $($images.Count) wallpapers in slideshow."
if ($skipped) { Write-Host "Skipped:"; $skipped | ForEach-Object { Write-Host "  - $_" } }
Write-Host "Undo with .\uninstall.ps1"
