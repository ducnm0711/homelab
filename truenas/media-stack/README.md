[ The End User ]
                            │
                            ▼
 ┌─────────────────────────────────────────────────────┐
 │                 Jellyfin (Media Server)             │
 │          Scans, transcodes, and streams media       │
 └──────────────────────────┬──────────────────────────┘
                            │ (Reads)
 ═══════════════════════════▼═══════════════════════════
        TrueNAS Dataset:  /mnt/pool/media 
 ═══════════════════════════▲═══════════════════════════
                            │ (Hardlinks / Moves)
 ┌──────────────────────────┴──────────────────────────┐
 │               The Control Plane                     │
 │      ┌──────────────┐       ┌──────────────┐        │
 │      │ Radarr       │       │ Sonarr       │        │
 │      │ (Movies)     │       │ (TV Shows)   │        │
 │      └──────┬───────┘       └──────┬───────┘        │
 │             │                      │                │
 │    ┌────────▼──────────────────────▼──────────┐     │
 │    │                 Bazarr                   │     │
 │    │           (Downloads Subtitles)          │     │
 │    └──────────────────────────────────────────┘     │
 └─────────────┬───────────────────────────┬───────────┘
               │ (Searches)                │ (Sends Download Jobs)
               ▼                           │
 ┌──────────────────────────┐              │
 │ Prowlarr (Indexer Mgmt)  │              │
 │  ├─► Uses Flaresolverr   │              │
 │  │   to bypass Cloudflare│              │
 └─────────────┬────────────┘              │
               │                           │
               ▼                           ▼
 ┌─────────────────────────────────────────────────────┐
 │                 Gluetun (VPN Gateway)               │
 │       (Creates a secure network namespace)          │
 │                                                     │
 │   ┌─────────────────┐       ┌─────────────────┐     │
 │   │ Prowlarr Traffic│       │ qBittorrent     │     │
 │   │ (Search queries)│       │ (Downloads)     │     │
 │   └─────────┬───────┘       └───────┬─────────┘     │
 └─────────────┼───────────────────────┼───────────────┘
               │                       │
               ▼                       ▼
    [ Blocked/Restricted Torrent Trackers & Swarms ]