# Minimal Dark for Windows 11

A clean, minimal dark setup for Windows 11 with a warm accent colour and a rotating
abstract wallpaper set on both the desktop and the lock screen. It only uses
built-in Windows settings, with no third-party customisation tools, and
`uninstall.ps1` puts back exactly what was there before.

![Wallpapers and accent colours](assets/preview.jpg)

## What it does

- **Look:** dark mode for apps and the system, transparency off, and one warm
  accent colour used only for highlights. The taskbar, Start and title bars are not tinted.
- **Wallpaper:** 13 dark abstract wallpapers (4K or larger), shuffled every 30 minutes.
- **Lock screen:** the same wallpapers, with a new one each time you sign in or unlock.
- **Taskbar:** left-aligned, with Task View, Widgets, Search and Copilot hidden.
- **Start:** no Recommended section, recent apps, most-used apps or tips.
- **File Explorer:** opens to This PC, compact view, file extensions shown,
  Gallery and Home recent/frequent items hidden.
- **Ads and tips:** lock-screen fun facts, Settings suggestions, "finish setting up"
  prompts and suggested apps are turned off.
- Your sounds, cursors, animations and screensaver are left alone.

## Install

```powershell
git clone https://github.com/lohanidamodar/wintheme.git
cd wintheme
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

You'll get a menu to pick the accent colour. To skip the menu, pass the colour directly:

```powershell
.\install.ps1 -Accent rose        # rose | terracotta | amber | sand
.\install.ps1 -Accent "#7FA3C2"   # or any hex colour
```

Run it again whenever you want to change the accent. Your original settings
stay backed up from the first run.

### Admin extras (optional)

```powershell
.\install.ps1 -Admin
```

This shows one UAC prompt and turns on a few settings that Windows only lets an
administrator change:

- Copilot turned off by policy
- No web or Bing results in Start search

Windows' anti-tamper protection blocks the Widgets policy even for
administrators, so Widgets is only hidden from the taskbar.

## Uninstall

```powershell
.\uninstall.ps1                    # restore everything
.\uninstall.ps1 -RemoveWallpapers  # also delete the downloaded images
```

The uninstall restores:

- every registry value, from `backup.json`
- your previous theme and lock screen image
- the admin extras, if you applied them
- removes the lock screen scheduled task

## Files

| File | Purpose |
|---|---|
| `install.ps1` | Applies everything; safe to re-run |
| `uninstall.ps1` | Restores from the backups |
| `settings.ps1` | The single list of settings and accent colours, shared by all scripts |
| `admin.ps1` | Admin-only extras; run by `-Admin`, or directly |
| `lockscreen.ps1` | Picks a random lock screen image; run by a scheduled task at sign-in and unlock |
| `wallpapers.json` | Wallpaper download links; edit it to change the set |

These are created locally and git-ignored: `wallpapers/`, `backup.json`,
`backup-theme.theme`, `backup-admin.json`, `MinimalDark.theme` and `admin.log`.

## Customising

- **Wallpapers:** add or remove entries in `wallpapers.json`, or drop your own
  `.jpg`/`.png` files into `wallpapers/`, then re-run `install.ps1`.
- **Accent colours:** edit the `$Accents` table at the top of `settings.ps1`.
- **Slideshow interval:** change `Interval` (milliseconds) in the `Slideshow`
  section of `install.ps1`.

## Wallpaper credits

The wallpapers are downloaded from [Wallhaven](https://wallhaven.cc) at install
time. Only the small thumbnails in the preview image are stored in this repo.
All rights belong to their creators:

[polllj](https://wallhaven.cc/w/polllj) ·
[xe7jjd](https://wallhaven.cc/w/xe7jjd) ·
[vpep35](https://wallhaven.cc/w/vpep35) ·
[jedzym](https://wallhaven.cc/w/jedzym) ·
[ml3jm8](https://wallhaven.cc/w/ml3jm8) ·
[gwd837](https://wallhaven.cc/w/gwd837) ·
[po78p3](https://wallhaven.cc/w/po78p3) ·
[mlg7qm](https://wallhaven.cc/w/mlg7qm) ·
[7j9wle](https://wallhaven.cc/w/7j9wle) ·
[gw2r2e](https://wallhaven.cc/w/gw2r2e) ·
[yqvzek](https://wallhaven.cc/w/yqvzek) ·
[1q22pg](https://wallhaven.cc/w/1q22pg) ·
[8g5qgy](https://wallhaven.cc/w/8g5qgy)

## Requirements

Windows 11 (tested on 25H2, build 26200) and Windows PowerShell 5.1, which is built in.
Everything except the admin extras runs as your normal user.
