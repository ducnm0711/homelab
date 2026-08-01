# Jellyfin & Media Automation Stack Deployment Guide

This repository contains the configuration and deployment guide for hosting Jellyfin and its surrounding media automation stack via Docker Compose (Portainer) on TrueNAS SCALE. 

The environment uses **Traefik v3** with **Tailscale** for secure subpath routing and SSL termination, **Gluetun** as a VPN gateway for torrenting hygiene, and a custom **Alpine init container** to handle Docker volume permissions automatically with structured JSON logging.

---

## Architecture Overview

### 1. Data Flow Diagram

```text
               [ The End User ]
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│               Jellyfin (Media Server)               │
│          Scans, transcodes, and streams media       │
└──────────────────────────┬──────────────────────────┘
                           │ (Reads)
═══════════════════════════▼═══════════════════════════
        TrueNAS Dataset:  /mnt/SSD/media 
═══════════════════════════▲═══════════════════════════
                           │ (Hardlinks / Moves)
┌──────────────────────────┴──────────────────────────┐
│                   The Control Plane                 │
│      ┌──────────────┐       ┌──────────────┐        │
│      │ Radarr       │       │ Sonarr       │        │
│      │ (Movies)     │       │ (TV Shows)   │        │
│      └──────┬───────┘       └──────┬───────┘        │
│             │                      │                │
│    ┌────────▼──────────────────────▼──────────┐     │
│    │                 Bazarr                   │     │
│    │          (Downloads Subtitles)           │     │
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
│                Gluetun (VPN Gateway)                │
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
```

### 2. Stack Summary

*   **Host OS:** TrueNAS SCALE (Debian-based)
*   **Deployment Engine:** Docker Compose via Portainer
*   **Media Server:** Jellyfin (`10.11.11`)
*   **Network Anchor / Proxy:** Traefik v3 (Subpath routing: `/jellyfin`)
*   **SSL / VPN:** Tailscale
*   **Permissions Management:** Custom Alpine init container


#### Host Directory Preparation:
Before deploying the stack, host directories must exist on your dataset and be assigned to the TrueNAS apps user (UID/GID 568) to prevent UnauthorizedAccessException errors on boot.

Run the following commands via SSH on the TrueNAS host:

```bash
# Assign ownership of config directories to user 568
sudo chown -R 568:568 /mnt/SSD/config/jellyfin

# Grant read/write/execute permissions
sudo chmod -R 775 /mnt/SSD/config/jellyfin

# Ensure your media directory is also accessible
sudo chown -R 568:568 /mnt/SSD/media
sudo chmod -R 775 /mnt/SSD/media
```