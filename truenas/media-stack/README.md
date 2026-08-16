# Jellyfin & Media Automation Stack Deployment Guide

Docker Compose stack for Jellyfin and media automation on TrueNAS SCALE (Portainer).

**Traefik v3** + **Tailscale** handle HTTPS subpath routing for consumer-facing apps. A one-shot **Alpine init container** fixes Jellyfin transcode volume permissions before Jellyfin starts.

---

## Services

| Service | Role | Access |
|---|---|---|
| **permissions-fix** | One-shot init: `chown`/`chmod` on transcode volume | — |
| **jellyfin** | Media server / streaming | Tailnet `/jellyfin` + LAN `:8096` |
| **radarr** | Movie automation | Tailnet `/radarr` + LAN `:7878` |
| **sonarr** | TV automation | Tailnet `/sonarr` + LAN `:8989` |
| **bazarr** | Subtitle automation | Tailnet `/bazarr` |
| **prowlarr** | Indexer manager | LAN `:9696` only |
| **qbittorrent** | Download client | LAN `:8080` + torrent `:6881` |

Traefik runs in the separate `vpn-stack`; this stack joins its external `proxy` network.

---

## Startup Order & Dependencies

Only one **hard** dependency exists in Compose: Jellyfin must not start until `permissions-fix` completes successfully. Without correct ownership on the transcode volume, Jellyfin will fail at runtime.

All other relationships are **soft** — services start independently and retry connections until their peers are reachable:

```text
permissions-fix ──► jellyfin          (hard: service_completed_successfully)

prowlarr  ─┐
qbittorrent┼──► radarr ──► bazarr     (soft: logical order only)
           │
           └──► sonarr                 (soft: parallel to Radarr)

radarr / sonarr ──► jellyfin           (soft: media appears when *arr imports)
```

| From | To | Type | Why |
|---|---|---|---|
| `permissions-fix` | `jellyfin` | **Hard** | Transcode cache must be owned by UID 568 before Jellyfin writes to it |
| `prowlarr` | `radarr` | Soft | Radarr pulls indexers from Prowlarr; retries if Prowlarr is still starting |
| `qbittorrent` | `radarr` | Soft | Radarr sends download jobs to qBittorrent; retries until the client responds |
| `prowlarr` | `sonarr` | Soft | Sonarr pulls indexers from Prowlarr; retries if Prowlarr is still starting |
| `qbittorrent` | `sonarr` | Soft | Sonarr sends download jobs to qBittorrent; retries until the client responds |
| `radarr` | `bazarr` | Soft | Bazarr reads the Radarr library for subtitle matching |
| `radarr` | `jellyfin` | Soft | Jellyfin scans `/media` on its own schedule — no Compose gate needed |
| `sonarr` | `jellyfin` | Soft | Jellyfin scans `/media` on its own schedule — no Compose gate needed |

`depends_on` entries for soft dependencies (if present) only influence start *preference*, not correctness. Every *arr app and qBittorrent is designed to wait and reconnect when upstream services come online.

---

## Architecture

### Data flow

```text
               [ The End User ]
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│               Jellyfin (Media Server)               │
│          Scans, transcodes, and streams media       │
└──────────────────────────┬──────────────────────────┘
                           │ (reads)
═══════════════════════════▼═══════════════════════════
     TrueNAS Dataset:  /mnt/tier-2-hdd-stripe-test/media
═══════════════════════════▲═══════════════════════════
                           │ (hardlinks / moves)
┌──────────────────────────┴──────────────────────────┐
│                   Control Plane                     │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐      │
│   │  Radarr  │───►│  Bazarr  │    │ Prowlarr │      │
│   │ (movies) │    │  (subs)  │    │(indexers)│      │
│   └────┬─────┘    └──────────┘    └────┬─────┘      │
│   ┌────┴─────┐                         │            │
│   │  Sonarr  │                         │            │
│   │   (TV)   │                         │            │
│   └────┬─────┘                         │            │
│        └──────────────┬────────────────┘            │
│                       │ (download jobs)             │
│                       ▼                             │
│               ┌──────────────┐                      │
│               │ qBittorrent  │                      │
│               └──────────────┘                      │
└─────────────────────────────────────────────────────┘
```

### Network exposure

| Tailnet (Traefik) | LAN only |
|---|---|
| Jellyfin, Radarr, Sonarr, Bazarr | Prowlarr, qBittorrent |

Prowlarr holds indexer credentials; qBittorrent controls downloads — both stay off the tailnet.

---

## Stack Summary

* **Host OS:** TrueNAS SCALE
* **Deployment:** Docker Compose via Portainer
* **Media server:** Jellyfin `10.11.11`
* **Proxy / SSL:** Traefik v3 + Tailscale (`homelab.akita-beaufort.ts.net`)
* **Permissions:** Alpine init container (`permissions-fix`)

---

## Host Directory Preparation

Config and media paths must exist and be owned by the TrueNAS apps user (UID/GID **568**) before first deploy.

```bash
# Config directories
sudo chown -R 568:568 /mnt/SSD/config/{jellyfin,bazarr,radarr,sonarr,prowlarr,qbittorrent}
sudo chmod -R 775 /mnt/SSD/config/{jellyfin,bazarr,radarr,sonarr,prowlarr,qbittorrent}

# Media dataset
sudo chown -R 568:568 /mnt/tier-2-hdd-stripe-test/media
sudo chmod -R 775 /mnt/tier-2-hdd-stripe-test/media
```

The `permissions-fix` init container handles the Jellyfin transcode Docker volume on every stack start; host paths above are a one-time prerequisite.
