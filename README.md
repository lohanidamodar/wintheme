# Minimal Dark for Windows 11

A clean, minimal dark setup for Windows 11 with a warm accent colour and a rotating set of calm,
minimal wallpapers (misty seas, Himalayan dusk and soft abstracts) on both the desktop and the lock screen. It only uses
built-in Windows settings, with no third-party customisation tools, and
`uninstall.ps1` puts back exactly what was there before.

![Wallpapers and accent colours](assets/preview.jpg)

## What it does

- **Look:** dark mode for apps and the system, transparency off, and one warm
  accent colour used only for highlights. The taskbar, Start and title bars are not tinted.
- **Wallpaper:** 39 calm 4K wallpapers, shuffled every 30 minutes: foggy seas and lakes,
  misty forests and mountains, 20 Nepali Himalayan landscapes, and a few soft abstracts.
- **Lock screen:** the same wallpapers, with a new one each time you sign in or unlock.
- **Taskbar:** centred icons, with Task View, Widgets, Search and Copilot hidden.
- **Start:** no Recommended section, recent apps, most-used apps or tips.
- **File Explorer:** opens to This PC, compact view, file extensions shown,
  Gallery and Home recent/frequent items hidden.
- **Ads and tips:** lock-screen fun facts, Settings suggestions, "finish setting up"
  prompts and suggested apps are turned off.
- **Windows Terminal:** a matching "Minimal Dark" colour scheme (charcoal background,
  accent-coloured cursor and selection) and a flat dark tab bar.
- Your sounds, cursors, animations and screensaver are left alone.

## Install

Open **PowerShell** (Start → type `powershell` → Enter), paste this and press Enter:

```powershell
irm https://raw.githubusercontent.com/lohanidamodar/wintheme/master/get.ps1 | iex
```

The installer:

1. Shows a menu to pick the accent colour.
2. Downloads everything to `%LOCALAPPDATA%\MinimalDark`.
3. Backs up your current settings.
4. Applies the theme.

The Settings app opens and closes on its own while the theme applies. You don't
need git, admin rights or any changes to your execution policy.

### Options

To skip the menu or add the admin extras, use this form and add the options at the end:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lohanidamodar/wintheme/master/get.ps1))) -Accent amber -Admin
```

| Option | What it does |
|---|---|
| `-Accent <name>` | `rose`, `terracotta`, `amber`, `sand`, or any hex colour such as `"#7FA3C2"` |
| `-Admin` | One UAC prompt. Turns Copilot off by policy and removes web/Bing results from Start search |

To change the accent later, or to update to the latest version, run the same
command again. Your original settings stay backed up from the first run.

Windows' anti-tamper protection blocks the Widgets policy even for administrators,
so Widgets is only hidden from the taskbar.

## Uninstall

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lohanidamodar/wintheme/master/get.ps1))) -Uninstall
```

Add `-RemoveWallpapers` to also delete the downloaded images. Uninstall restores:

- every registry value, from the backup
- your previous theme and lock screen image
- your previous Windows Terminal colour scheme and theme
- the admin extras, if you applied them (one UAC prompt)

It also removes the lock screen scheduled task.

### From a clone instead

```powershell
git clone https://github.com/lohanidamodar/wintheme.git
cd wintheme
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Accent rose
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Only one copy can be installed at a time. If you try to install a second copy,
it stops and tells you where the first one is.

## Files

| File | Purpose |
|---|---|
| `get.ps1` | One-line installer: downloads the latest version and runs install or uninstall |
| `install.ps1` | Applies everything; safe to re-run |
| `uninstall.ps1` | Restores from the backups |
| `settings.ps1` | The single list of settings and accent colours, shared by all scripts |
| `admin.ps1` | Admin-only extras; run by `-Admin`, or directly |
| `lockscreen.ps1` | Picks a random lock screen image; run by a scheduled task at sign-in and unlock |
| `wallpapers.json` | The wallpaper list: file name, download link, licence, author and source |
| `assets/wallpapers/` | Wallpapers made for this theme (CC0) |
| `tools/wallpapers.html` | The generator for those; render a design with headless Edge (see the comment at the top) |

These are created locally and git-ignored: `wallpapers/`, `backup.json`,
`backup-theme.theme`, `backup-admin.json`, `MinimalDark.theme` and `admin.log`.

## Customising

- **Wallpapers:** add or remove entries in `wallpapers.json`, then re-run the install command.
  Entries you remove are deleted from `wallpapers/`. You can also drop your own `.jpg`/`.png` files
  into `%LOCALAPPDATA%\MinimalDark\wallpapers`; the installer never deletes those.
- **Accent colours:** edit the `$Accents` table at the top of `settings.ps1`.
- **Slideshow interval:** change `Interval` (milliseconds) in the `Slideshow`
  section of `install.ps1`.

## Wallpaper credits

Wallpapers are downloaded at install time, so only the two generated ones and
the small preview thumbnails are stored in this repo.

**Made for this theme** (`assets/wallpapers/`), dedicated to the public domain (CC0).

**From Wikimedia Commons**, all CC0. Attribution isn't required, but thanks to the photographers:

- [Aaron Benson 2017-01-25 (Unsplash)](https://commons.wikimedia.org/wiki/File:Aaron_Benson_2017-01-25_(Unsplash).jpg) by Aaron Benson aaronbphoto
- [Aaron Benson 2017-01-27 (Unsplash)](https://commons.wikimedia.org/wiki/File:Aaron_Benson_2017-01-27_(Unsplash).jpg) by Aaron Benson aaronbphoto
- [Annapurna Ranges (Unsplash)](https://commons.wikimedia.org/wiki/File:Annapurna_Ranges_(Unsplash).jpg) by Daniel Leone danielleone
- [Annapurna Ranges 1 (Unsplash)](https://commons.wikimedia.org/wiki/File:Annapurna_Ranges_1_(Unsplash).jpg) by Daniel Leone danielleone
- [Boating on Phewa Lake, Pokhara, Nepal (Unsplash)](https://commons.wikimedia.org/wiki/File:Boating_on_Phewa_Lake,_Pokhara,_Nepal_(Unsplash).jpg) by Payas payas
- [Dusk from Kirtipur, Nepal](https://commons.wikimedia.org/wiki/File:Dusk_from_Kirtipur,_Nepal.jpg) by Anixkhatri01
- [Early morning light at the top of Poon Hill2](https://commons.wikimedia.org/wiki/File:Early_morning_light_at_the_top_of_Poon_Hill2.jpg) by Ali Sabbagh
- [Foggy Water Reflections (Unsplash)](https://commons.wikimedia.org/wiki/File:Foggy_Water_Reflections_(Unsplash).jpg) by Matthew Henry matthewhenry
- [Fog rolling in over Brofjorden](https://commons.wikimedia.org/wiki/File:Fog_rolling_in_over_Brofjorden.jpg) by W.carter
- [Gray Day At Sea (Unsplash)](https://commons.wikimedia.org/wiki/File:Gray_Day_At_Sea_(Unsplash).jpg) by Ali Inay inayali
- [Himalayas 1 (Unsplash)](https://commons.wikimedia.org/wiki/File:Himalayas_1_(Unsplash).jpg) by Sergey Pesterev sickle
- [Kanchenjunga South Peak (Unsplash)](https://commons.wikimedia.org/wiki/File:Kanchenjunga_South_Peak_(Unsplash).jpg) by Mukesh Jain hocus_phocus
- [Kathmandu Valley panoramic view from Shivapuri hills under haze](https://commons.wikimedia.org/wiki/File:Kathmandu_Valley_panoramic_view_from_Shivapuri_hills_under_haze.jpg) by Krishna k. sahh
- [Lakeside Sunset in Nepal (Unsplash)](https://commons.wikimedia.org/wiki/File:Lakeside_Sunset_in_Nepal_(Unsplash).jpg) by Igor Ovsyannykov igorovsyannykov
- [Lost direction (Unsplash)](https://commons.wikimedia.org/wiki/File:Lost_direction_(Unsplash).jpg) by Eugeniu Esanu sanesan
- [Misty forest 1 Whatcom County](https://commons.wikimedia.org/wiki/File:Misty_forest_1_Whatcom_County.jpg) by U.S. Department of Agriculture
- [Misty Icelandic mountain (Unsplash)](https://commons.wikimedia.org/wiki/File:Misty_Icelandic_mountain_(Unsplash).jpg) by Jeremy Goldberg jeremy
- [Misty morning mountain (Unsplash)](https://commons.wikimedia.org/wiki/File:Misty_morning_mountain_(Unsplash).jpg) by jesse orrico jessedo81
- [Misty Mountains (Unsplash zR40wedS1aQ)](https://commons.wikimedia.org/wiki/File:Misty_Mountains_(Unsplash_zR40wedS1aQ).jpg) by James Bloedel j_bloedel
- [Monochrome ships on horizon (Unsplash)](https://commons.wikimedia.org/wiki/File:Monochrome_ships_on_horizon_(Unsplash).jpg) by Tim Mossholder timmossholder
- [Mountains and a twinkling sky (Unsplash)](https://commons.wikimedia.org/wiki/File:Mountains_and_a_twinkling_sky_(Unsplash).jpg) by Martin StanÄ›k martinstanek
- [Mt.Langtang](https://commons.wikimedia.org/wiki/File:Mt.Langtang.jpg) by Pudasaini07
- [Nirvana Garden with Himalchuli Mountain](https://commons.wikimedia.org/wiki/File:Nirvana_Garden_with_Himalchuli_Mountain.jpg) by Nir gurung
- [Om mani padme hum (Unsplash)](https://commons.wikimedia.org/wiki/File:Om_mani_padme_hum_(Unsplash).jpg) by Kalle K kallek
- [Ostseestrand bei leichtem Nebel](https://commons.wikimedia.org/wiki/File:Ostseestrand_bei_leichtem_Nebel.JPG) by Pogobuschel
- [Poon Hill PANO 20180323 075733](https://commons.wikimedia.org/wiki/File:Poon_Hill_PANO_20180323_075733.jpg) by Ermakae
- [Rara lake beauty](https://commons.wikimedia.org/wiki/File:Rara_lake_beauty.jpg) by scvishnu7, phuchche
- [Reculver Minimalist Foggy Seascape Long Exposure (Unsplash)](https://commons.wikimedia.org/wiki/File:Reculver_Minimalist_Foggy_Seascape_Long_Exposure_(Unsplash).jpg) by Carl Revell sprogz
- [Rising sun (Unsplash)](https://commons.wikimedia.org/wiki/File:Rising_sun_(Unsplash).jpg) by Christopher Burns christopher__burns
- [Ruhige See (Unsplash)](https://commons.wikimedia.org/wiki/File:Ruhige_See_(Unsplash).jpg) by Eric WÃ¼stenhagen knipsograf
- [Snowy mountains1](https://commons.wikimedia.org/wiki/File:Snowy_mountains1.jpg) by Ali Sabbagh
- [Sunset in the Himalayas (Unsplash)](https://commons.wikimedia.org/wiki/File:Sunset_in_the_Himalayas_(Unsplash).jpg) by Sergey Pesterev sickle
- [Swallowed in the Sea (Unsplash)](https://commons.wikimedia.org/wiki/File:Swallowed_in_the_Sea_(Unsplash).jpg) by Paul paul_
- [The silence of light (Unsplash)](https://commons.wikimedia.org/wiki/File:The_silence_of_light_(Unsplash).jpg) by Simon Buchou simon_buchou

**From Wallhaven** (not CC0; downloaded for personal use, all rights belong to their creators):
[polllj](https://wallhaven.cc/w/polllj) · [xe7jjd](https://wallhaven.cc/w/xe7jjd) · [1q22pg](https://wallhaven.cc/w/1q22pg)

## Requirements

Windows 11 (tested on 25H2, build 26200) and Windows PowerShell 5.1, which is built in.
Everything except the admin extras runs as your normal user.
