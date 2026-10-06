# Single source of truth for every registry value the theme touches.
# Dot-source this file; it defines $Accent and $Settings.

$Accent = @{ R = 0xC2; G = 0x7C; B = 0x88 }   # rose #C27C88

function Get-AccentPalette($c) {
    # 8 RGBA entries: light3, light2, light1, accent, dark1, dark2, dark3, extra
    $mix = { param($v, $t, $f) [byte][math]::Round($v + ($t - $v) * $f) }
    $steps = @(@(255, .6), @(255, .4), @(255, .2), @(0, 0), @(0, .2), @(0, .4), @(0, .6), @(0, .4))
    $bytes = foreach ($s in $steps) {
        & $mix $c.R $s[0] $s[1]; & $mix $c.G $s[0] $s[1]; & $mix $c.B $s[0] $s[1]; 0
    }
    [byte[]]$bytes
}

# DWM/Accent DWORDs are ABGR; ColorizationColor is ARGB.
$abgr = [BitConverter]::ToInt32([byte[]]($Accent.R, $Accent.G, $Accent.B, 0xFF), 0)
$argb = [BitConverter]::ToInt32([byte[]]($Accent.B, $Accent.G, $Accent.R, 0xC4), 0)

$cv  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion'
$adv = "$cv\Explorer\Advanced"
$cdm = "$cv\ContentDeliveryManager"

$Settings = @(
    # Look
    @{ Path = "$cv\Themes\Personalize"; Name = 'AppsUseLightTheme';   Type = 'DWord'; Value = 0 }
    @{ Path = "$cv\Themes\Personalize"; Name = 'SystemUsesLightTheme'; Type = 'DWord'; Value = 0 }
    @{ Path = "$cv\Themes\Personalize"; Name = 'EnableTransparency';  Type = 'DWord'; Value = 0 }
    @{ Path = "$cv\Themes\Personalize"; Name = 'ColorPrevalence';     Type = 'DWord'; Value = 0 }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\DWM'; Name = 'ColorPrevalence';   Type = 'DWord'; Value = 0 }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\DWM'; Name = 'AccentColor';       Type = 'DWord'; Value = $abgr }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\DWM'; Name = 'ColorizationColor'; Type = 'DWord'; Value = $argb }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\DWM'; Name = 'ColorizationAfterglow'; Type = 'DWord'; Value = $argb }
    @{ Path = "$cv\Explorer\Accent"; Name = 'AccentColorMenu'; Type = 'DWord';  Value = $abgr }
    @{ Path = "$cv\Explorer\Accent"; Name = 'StartColorMenu';  Type = 'DWord';  Value = $abgr }
    @{ Path = "$cv\Explorer\Accent"; Name = 'AccentPalette';   Type = 'Binary'; Value = (Get-AccentPalette $Accent) }
    @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'AutoColorization'; Type = 'DWord'; Value = 0 }

    # Taskbar
    @{ Path = $adv; Name = 'TaskbarAl';          Type = 'DWord'; Value = 0 }
    @{ Path = $adv; Name = 'ShowTaskViewButton'; Type = 'DWord'; Value = 0 }
    @{ Path = $adv; Name = 'TaskbarDa';          Type = 'DWord'; Value = 0 }
    @{ Path = $adv; Name = 'ShowCopilotButton';  Type = 'DWord'; Value = 0 }
    @{ Path = "$cv\Search"; Name = 'SearchboxTaskbarMode'; Type = 'DWord'; Value = 0 }

    # Start
    @{ Path = $adv; Name = 'Start_TrackDocs';            Type = 'DWord'; Value = 0 }
    @{ Path = $adv; Name = 'Start_TrackProgs';           Type = 'DWord'; Value = 0 }
    @{ Path = $adv; Name = 'Start_IrisRecommendations';  Type = 'DWord'; Value = 0 }
    @{ Path = $adv; Name = 'Start_AccountNotifications'; Type = 'DWord'; Value = 0 }
    @{ Path = "$cv\Start"; Name = 'ShowRecentList';   Type = 'DWord'; Value = 0 }
    @{ Path = "$cv\Start"; Name = 'ShowFrequentList'; Type = 'DWord'; Value = 0 }

    # Explorer
    @{ Path = $adv; Name = 'HideFileExt';    Type = 'DWord'; Value = 0 }
    @{ Path = $adv; Name = 'LaunchTo';       Type = 'DWord'; Value = 1 }
    @{ Path = $adv; Name = 'UseCompactMode'; Type = 'DWord'; Value = 1 }
    @{ Path = "$cv\Explorer"; Name = 'ShowRecent';   Type = 'DWord'; Value = 0 }
    @{ Path = "$cv\Explorer"; Name = 'ShowFrequent'; Type = 'DWord'; Value = 0 }
    @{ Path = 'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'; Name = 'System.IsPinnedToNameSpaceTree'; Type = 'DWord'; Value = 0 }

    # Ads and tips
    @{ Path = $cdm; Name = 'RotatingLockScreenOverlayEnabled'; Type = 'DWord'; Value = 0 }
    @{ Path = $cdm; Name = 'SubscribedContent-338387Enabled';  Type = 'DWord'; Value = 0 }
    @{ Path = $cdm; Name = 'SubscribedContent-338389Enabled';  Type = 'DWord'; Value = 0 }
    @{ Path = $cdm; Name = 'SubscribedContent-338393Enabled';  Type = 'DWord'; Value = 0 }
    @{ Path = $cdm; Name = 'SubscribedContent-353694Enabled';  Type = 'DWord'; Value = 0 }
    @{ Path = $cdm; Name = 'SubscribedContent-353696Enabled';  Type = 'DWord'; Value = 0 }
    @{ Path = $cdm; Name = 'SoftLandingEnabled';               Type = 'DWord'; Value = 0 }
    @{ Path = $cdm; Name = 'SilentInstalledAppsEnabled';       Type = 'DWord'; Value = 0 }
    @{ Path = $cdm; Name = 'SystemPaneSuggestionsEnabled';     Type = 'DWord'; Value = 0 }
    @{ Path = "$cv\UserProfileEngagement"; Name = 'ScoobeSystemSettingEnabled'; Type = 'DWord'; Value = 0 }
)

function Test-SettingValue($s, $actual) {
    if ($s.Type -eq 'Binary') { return ($null -ne $actual) -and ((Compare-Object $actual $s.Value -SyncWindow 0) -eq $null) }
    if ($null -eq $actual) { return $false }
    if ($s.Type -eq 'DWord') { return ([int64]$actual -band 4294967295) -eq ([int64]$s.Value -band 4294967295) }   # signed vs unsigned
    return $actual -eq $s.Value
}

function Get-RegValue($path, $name) {
    $item = Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
    if ($item) { $item.$name } else { $null }
}

function Restart-Explorer {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
}

function Invoke-Theme($themePath) {
    # Applying a .theme opens the Settings app; close it once the theme lands.
    # Windows copies the file into its Themes folder, so match on the file name.
    $leaf = Split-Path $themePath -Leaf
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        Start-Process -FilePath $themePath
        for ($i = 0; $i -lt 40; $i++) {
            Start-Sleep -Milliseconds 500
            $now = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes').CurrentTheme
            if ((Split-Path $now -Leaf) -eq $leaf) { break }
        }
        Start-Sleep -Seconds 3
        Stop-Process -Name SystemSettings -Force -ErrorAction SilentlyContinue
        if ((Split-Path $now -Leaf) -eq $leaf) { return $true }
        Start-Sleep -Seconds 2
    }
    return $false
}

function Assert-InteractiveUser {
    $owner = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" |
        Select-Object -First 1 | Invoke-CimMethod -MethodName GetOwner
    if ($owner -and $owner.User -ne $env:USERNAME) {
        throw "Running as '$env:USERNAME' but the desktop belongs to '$($owner.User)'. Run without elevation as the desktop user."
    }
}
