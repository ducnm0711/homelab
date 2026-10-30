# Media naming and management rules

This document defines naming, download cleanup, and subtitle rules for the TrueNAS media stack.
The rules apply to Radarr, Sonarr, Bazarr, and qBittorrent.
The file names use kebab-case.
Kebab-case is safer for Linux and POSIX shells, media libraries, and CLI workflows.

## Naming formats

| Item | Format | Example |
| :--- | :--- | :--- |
| Movie file | `{movie-cleantitle}-{release-year}-{edition-tags}-{quality-title}` | `the-movie-title-2010-ultimate-extended-edition-bluray-1080p` |
| Movie folder | `{movie-cleantitle}-{release-year}` | `the-movie-title-2010` |
| Series folder | `{series-cleantitle}-{series-year}` | `the-series-title-2015` |
| Season folder | `season-{season:00}` | `season-01` |
| Standard episode | `{series-cleantitle}-s{season:00}e{episode:00}-{quality-title}` | `the-series-title-s01e02-bluray-1080p` |
| Air-date episode | `{series-cleantitle}-{air-date}-{quality-title}` | `the-series-title-2015-01-02-bluray-1080p` |
| Absolute episode | `{series-cleantitle}-s{season:00}e{episode:00}-{absolute:000}-{quality-title}` | `the-series-title-s01e02-002-bluray-1080p` |

## Torrent cleanup and seeding

Radarr and Sonarr import media by hardlink or copy.
The raw download stays in place while qBittorrent seeds the torrent.
Radarr or Sonarr deletes the raw file after qBittorrent stops the torrent.
This cleanup needs two settings.
One setting is in Radarr and Sonarr.
The other setting is in qBittorrent.

### Radarr and Sonarr cleanup

1. Open `Settings > Download Clients` in Radarr and Sonarr.
2. Show the advanced settings with the gear icon.
3. Find `Completed Download Handling`.
4. Enable `Remove Completed`.

### qBittorrent thresholds

1. Open `Tools > Options > BitTorrent` in qBittorrent.
2. Set the download rate threshold to `2` KiB/s.
3. Set the upload rate threshold to `2` KiB/s.
4. Set the torrent inactivity timer to `60` seconds.

### qBittorrent seeding limit

1. Find `Seeding Limits`.
2. Set `When ratio reaches` to `0.3`.
3. Set `When total seeding time reaches` to `4320` minutes (`72` hours).
4. Set `When inactive seeding time reaches` to `4320` minutes (`72` hours).
5. Select `Any of the above`.
6. Set the action to `Stop torrent`.

### Cleanup sequence

1. qBittorrent stops the torrent when any limit is met.
2. The limits are ratio `0.3`, `4320` minutes of total seeding, and `4320` minutes of inactive seeding.
3. Radarr or Sonarr detects the stopped torrent.
4. The `Remove Completed` rule deletes the raw download file.
5. The imported and renamed media file stays in `/movies` or `/series`.

## Subtitle sources

Bazarr manages subtitles for the movie and series libraries.
Use two free sources.
Both sources need an account.

| Source | Account | Purpose |
| :--- | :--- | :--- |
| OpenSubtitles | Required | Subtitle search and download. |
| SubDL | Required | Subtitle search and download. |

Add the accounts in Bazarr.
Then set the preferred languages.

## Storage paths

The media stack uses two media pools and one configuration pool.
The paths are the same in every container.

| Path | Content |
| :--- | :--- |
| `/mnt/media-01` | Movies. |
| `/mnt/media-02` | Series. |
| `/mnt/fast/app/<service>` | Service configuration. |

Radarr, Sonarr, Bazarr, qBittorrent, and Jellyfin mount the same media paths.
This shared layout allows hardlinks during import.
The compose file has no separate download directory.
qBittorrent stores downloads on the same media pools.

## Related documents

- [Media stack](media-stack.md)
- [Storage pools](storage.md)
- [TrueNAS deployment](../deployment/README.md)
