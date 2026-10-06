# Shared definitions for install.ps1, uninstall.ps1, admin.ps1 and lockscreen.ps1.
# Dot-source this file.

$Accents = [ordered]@{
    rose       = '#C27C88'
    terracotta = '#C8775A'
    amber      = '#D49A4A'
    sand       = '#C9A97E'
}
$DefaultAccent = 'rose'

function Resolve-Accent($name) {
    if ($Accents.Contains("$name".ToLower())) { return $Accents["$name".ToLower()] }
    if ("$name" -match '^#?[0-9A-Fa-f]{6}$') { return '#' + "$name".TrimStart('#').ToUpper() }
    throw "Unknown accent '$name'. Use one of: $($Accents.Keys -join ', '), or a hex colour like #C27C88."
}

function Get-AccentColors($hex) {
    $r = [Convert]::ToByte($hex.Substring(1, 2), 16)
    $g = [Convert]::ToByte($hex.Substring(3, 2), 16)
    $b = [Convert]::ToByte($hex.Substring(5, 2), 16)
    # AccentPalette: 8 RGBA entries - light3, light2, light1, accent, dark1, dark2, dark3, extra
    $mix = { param($v, $t, $f) [byte][math]::Round($v + ($t - $v) * $f) }
    $steps = @(@(255, .6), @(255, .4), @(255, .2), @(0, 0), @(0, .2), @(0, .4), @(0, .6), @(0, .4))
    $palette = foreach ($s in $steps) { & $mix $r $s[0] $s[1]; & $mix $g $s[0] $s[1]; & $mix $b $s[0] $s[1]; 0 }
    @{
        R = $r; G = $g; B = $b
        Abgr    = [BitConverter]::ToInt32([byte[]]($r, $g, $b, 0xFF), 0)   # DWM/Accent DWORDs
        Argb    = [BitConverter]::ToInt32([byte[]]($b, $g, $r, 0xC4), 0)   # ColorizationColor
        Palette = [byte[]]$palette
    }
}

function Get-Settings($hex) {
    $c   = Get-AccentColors $hex
    $cv  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion'
    $adv = "$cv\Explorer\Advanced"
    $cdm = "$cv\ContentDeliveryManager"
    $dwm = 'HKCU:\Software\Microsoft\Windows\DWM'
    @(
        # Look
        @{ Path = "$cv\Themes\Personalize"; Name = 'AppsUseLightTheme';    Type = 'DWord'; Value = 0 }
        @{ Path = "$cv\Themes\Personalize"; Name = 'SystemUsesLightTheme'; Type = 'DWord'; Value = 0 }
        @{ Path = "$cv\Themes\Personalize"; Name = 'EnableTransparency';   Type = 'DWord'; Value = 0 }
        @{ Path = "$cv\Themes\Personalize"; Name = 'ColorPrevalence';      Type = 'DWord'; Value = 0 }
        @{ Path = $dwm; Name = 'ColorPrevalence';       Type = 'DWord'; Value = 0 }
        @{ Path = $dwm; Name = 'AccentColor';           Type = 'DWord'; Value = $c.Abgr }
        @{ Path = $dwm; Name = 'ColorizationColor';     Type = 'DWord'; Value = $c.Argb }
        @{ Path = $dwm; Name = 'ColorizationAfterglow'; Type = 'DWord'; Value = $c.Argb }
        @{ Path = "$cv\Explorer\Accent"; Name = 'AccentColorMenu'; Type = 'DWord';  Value = $c.Abgr }
        @{ Path = "$cv\Explorer\Accent"; Name = 'StartColorMenu';  Type = 'DWord';  Value = $c.Abgr }
        @{ Path = "$cv\Explorer\Accent"; Name = 'AccentPalette';   Type = 'Binary'; Value = $c.Palette }
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

        # Lock screen: our own images instead of Spotlight
        @{ Path = $cdm; Name = 'RotatingLockScreenEnabled'; Type = 'DWord'; Value = 0 }

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
}

# Values Windows only lets an elevated process write. Applied by admin.ps1.
$AdminSettings = @(
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Type = 'DWord'; Value = 1 }
    @{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Type = 'DWord'; Value = 1 }
    @{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Type = 'DWord'; Value = 1 }  # no web results in Start search
)

function Test-SettingValue($s, $actual) {
    if ($null -eq $actual) { return $false }
    if ($s.Type -eq 'Binary') { return $null -eq (Compare-Object $actual $s.Value -SyncWindow 0) }
    if ($s.Type -eq 'DWord') { return ([int64]$actual -band 4294967295) -eq ([int64]$s.Value -band 4294967295) }   # signed vs unsigned
    return $actual -eq $s.Value
}

function Get-RegValue($path, $name) {
    $item = Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
    if ($item) { $item.$name } else { $null }
}

function Get-BackupEntries($settings, $existing) {
    # Keeps entries already backed up; adds the current value of any setting not yet recorded.
    $entries = [System.Collections.ArrayList]@(@($existing) | Where-Object { $_ })
    foreach ($s in $settings) {
        if ($entries | Where-Object { $_.Path -eq $s.Path -and $_.Name -eq $s.Name }) { continue }
        $key = Get-Item -Path $s.Path -ErrorAction SilentlyContinue
        $exists = [bool]($key -and ($key.GetValueNames() -contains $s.Name))
        $entry = [pscustomobject][ordered]@{ Path = $s.Path; Name = $s.Name; Exists = $exists; Kind = $null; Value = $null }
        if ($exists) {
            $entry.Kind = $key.GetValueKind($s.Name).ToString()
            $v = $key.GetValue($s.Name, $null, 'DoNotExpandEnvironmentNames')
            $entry.Value = if ($v -is [byte[]]) { [Convert]::ToBase64String($v) } else { $v }
        }
        [void]$entries.Add($entry)
    }
    , $entries.ToArray()
}

function Set-Values($settings) {
    # Returns the names that could not be set.
    foreach ($s in $settings) {
        try {
            if (-not (Test-Path $s.Path)) { New-Item -Path $s.Path -Force | Out-Null }
            Set-ItemProperty -Path $s.Path -Name $s.Name -Value $s.Value -Type $s.Type
        } catch {
            if (Test-SettingValue $s (Get-RegValue $s.Path $s.Name)) { continue }   # protected but already correct
            Write-Warning "Could not set $($s.Name): $($_.Exception.Message)"
            "$($s.Name) (write blocked)"
        }
    }
}

function Restore-Values($entries) {
    # Returns the names that could not be restored.
    foreach ($e in $entries) {
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
            $e.Name
        }
    }
}

function Restart-Explorer {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
}

function Invoke-Theme($themePath) {
    # Applying a .theme opens the Settings app; close it once the theme lands.
    # Windows copies the file into its Themes folder, so match on the file name.
    # Re-applying an already used name makes Windows save it as "Name (2).theme".
    $pattern = '^' + [regex]::Escape([IO.Path]::GetFileNameWithoutExtension($themePath)) + '( \(\d+\))?\.theme$'
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        Start-Process -FilePath $themePath
        for ($i = 0; $i -lt 40; $i++) {
            Start-Sleep -Milliseconds 500
            $now = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes').CurrentTheme
            if ((Split-Path $now -Leaf) -match $pattern) { break }
        }
        Start-Sleep -Seconds 3
        Stop-Process -Name SystemSettings -Force -ErrorAction SilentlyContinue
        if ((Split-Path $now -Leaf) -match $pattern) { return $true }
        Start-Sleep -Seconds 2
    }
    return $false
}

function Invoke-WinRT($operation, [type]$resultType) {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq $(if ($resultType) { 'IAsyncOperation`1' } else { 'IAsyncAction' })
    } | Select-Object -First 1
    if ($resultType) { $asTask = $asTask.MakeGenericMethod($resultType) }
    $task = $asTask.Invoke($null, @($operation))
    [void]$task.Wait(-1)
    if ($resultType) { $task.Result }
}

function Get-LockScreenImage {
    [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType=WindowsRuntime] | Out-Null
    $uri = [Windows.System.UserProfile.LockScreen]::OriginalImageFile
    if ($uri -and $uri.IsFile) { $uri.LocalPath } else { $null }
}

function Set-LockScreenImage($path) {
    [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime] | Out-Null
    [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType=WindowsRuntime] | Out-Null
    $file = Invoke-WinRT ([Windows.Storage.StorageFile]::GetFileFromPathAsync($path)) ([Windows.Storage.StorageFile])
    Invoke-WinRT ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($file))
}

$LockTaskName = 'MinimalDark Lock Screen'

function Assert-InteractiveUser {
    $owner = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" |
        Select-Object -First 1 | Invoke-CimMethod -MethodName GetOwner
    if ($owner -and $owner.User -ne $env:USERNAME) {
        throw "Running as '$env:USERNAME' but the desktop belongs to '$($owner.User)'. Use an account that is the signed-in user."
    }
}

function Test-Elevated {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ---------- Windows Terminal ----------
$TerminalSchemeName = 'Minimal Dark'
$TerminalFragmentDir = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Fragments\MinimalDark"

function Get-TerminalSettingsPaths {
    @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    ) | Where-Object { Test-Path $_ }
}

function Get-TerminalScheme($hex) {
    [ordered]@{
        name = $TerminalSchemeName
        background = '#161618'; foreground = '#D6D2CE'
        cursorColor = $hex; selectionBackground = $hex
        black  = '#1E1E21'; red  = '#C9626B'; green  = '#8FAE7E'; yellow  = '#D4A55A'
        blue   = '#7C93B8'; purple = '#A887B5'; cyan  = '#79A8A6'; white  = '#CFCAC4'
        brightBlack = '#5A5A60'; brightRed = '#E07A82'; brightGreen = '#A6C493'; brightYellow = '#E6BC77'
        brightBlue  = '#96ACCF'; brightPurple = '#C1A1CC'; brightCyan = '#95C2BF'; brightWhite = '#F2EEEA'
    }
}

function Format-Json([string]$json) {
    # Windows PowerShell 5.1 indents ConvertTo-Json output oddly; re-indent with 4 spaces.
    $indent = 0
    $lines = foreach ($raw in ($json -split "\r?\n")) {
        $line = $raw.Trim()
        if ($line -match '^[\}\]]') { $indent-- }
        ('    ' * [math]::Max($indent, 0)) + ($line -replace '^("(?:[^"\\]|\\.)*"):\s+', '$1: ')
        if ($line -match '[\{\[]$') { $indent++ }
    }
    ($lines -join "`r`n") -replace '\[\s*\]', '[]' -replace '\{\s*\}', '{}' -replace '\x5Cu0027', "'" -replace '\x5Cu003c', '<' -replace '\x5Cu003e', '>' -replace '\x5Cu0026', '&'
}

function Read-TerminalSettings($path) {
    try { Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $null }   # null when it has comments
}

function Write-TerminalSettings($path, $json) {
    Format-Json (ConvertTo-Json -InputObject $json -Depth 50) | Set-Content $path -Encoding UTF8
}

function Get-TerminalBackup {
    # Records what we are about to change in each settings.json.
    foreach ($path in Get-TerminalSettingsPaths) {
        $j = Read-TerminalSettings $path
        if (-not $j) { continue }
        $defaults = $j.profiles.defaults
        [pscustomobject][ordered]@{
            Path          = $path
            DefaultScheme = if ($defaults -and $defaults.PSObject.Properties.Name -contains 'colorScheme') { $defaults.colorScheme } else { $null }
            Theme         = if ($j.PSObject.Properties.Name -contains 'theme') { $j.theme } else { $null }
        }
    }
}

function Install-Terminal($hex) {
    # Returns a list of problems; empty when everything worked.
    if (-not (Get-TerminalSettingsPaths)) { return }
    New-Item -ItemType Directory -Force $TerminalFragmentDir | Out-Null
    $fragment = [ordered]@{ schemes = @(Get-TerminalScheme $hex) }
    Format-Json (ConvertTo-Json -InputObject $fragment -Depth 5) | Set-Content "$TerminalFragmentDir\minimal-dark.json" -Encoding UTF8

    $theme = [ordered]@{
        name   = $TerminalSchemeName
        window = [ordered]@{ applicationTheme = 'dark'; useMica = $false }
        tabRow = [ordered]@{ background = '#161618FF'; unfocusedBackground = '#161618FF' }
        tab    = [ordered]@{ background = 'terminalBackground'; unfocusedBackground = '#161618FF'; showCloseButton = 'hover' }
    }
    foreach ($path in Get-TerminalSettingsPaths) {
        $j = Read-TerminalSettings $path
        if (-not $j) { "Terminal settings has comments, set the '$TerminalSchemeName' scheme yourself: $path"; continue }
        if (-not $j.profiles.defaults) { $j.profiles | Add-Member defaults ([pscustomobject]@{}) -Force }
        $j.profiles.defaults | Add-Member colorScheme $TerminalSchemeName -Force
        $themes = @(@($j.themes) | Where-Object { $_ -and $_.name -ne $TerminalSchemeName }) + [pscustomobject]$theme
        $j | Add-Member themes $themes -Force
        $j | Add-Member theme $TerminalSchemeName -Force
        Write-TerminalSettings $path $j
    }
}

function Uninstall-Terminal($backup) {
    Remove-Item $TerminalFragmentDir -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($b in @($backup)) {
        if (-not $b -or -not (Test-Path $b.Path)) { continue }
        $j = Read-TerminalSettings $b.Path
        if (-not $j) { "Terminal settings has comments, reset the colour scheme yourself: $($b.Path)"; continue }
        $d = $j.profiles.defaults
        if ($d -and $d.colorScheme -eq $TerminalSchemeName) {
            if ($b.DefaultScheme) { $d.colorScheme = $b.DefaultScheme } else { $d.PSObject.Properties.Remove('colorScheme') }
        }
        if ($j.theme -eq $TerminalSchemeName) {
            if ($b.Theme) { $j.theme = $b.Theme } else { $j.PSObject.Properties.Remove('theme') }
        }
        if ($j.PSObject.Properties.Name -contains 'themes') {
            $j.themes = @(@($j.themes) | Where-Object { $_ -and $_.name -ne $TerminalSchemeName })
        }
        Write-TerminalSettings $b.Path $j
    }
}
