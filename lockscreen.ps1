# Sets the lock screen to a random wallpaper from wallpapers\.
# Run by the "MinimalDark Lock Screen" scheduled task at sign-in and unlock.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\settings.ps1"

$images = Get-ChildItem "$PSScriptRoot\wallpapers" -File | Where-Object Extension -in '.jpg', '.png'
if (-not $images) { exit 0 }
$current = Get-LockScreenImage
$pick = $images | Where-Object { $_.Name -ne (Split-Path "$current" -Leaf) } | Get-Random
if (-not $pick) { $pick = $images | Get-Random }
Set-LockScreenImage $pick.FullName
