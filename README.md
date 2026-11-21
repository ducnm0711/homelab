# Homelab

This repository holds my homelab configuration.
Each top-level folder is a first-class domain with its own lifecycle and tooling.

## Repository taxonomy

| Folder | Purpose | Entry point |
| :--- | :--- | :--- |
| `hosts/` | Persistent bare-metal servers and NAS hosts. | [hosts/README.md](hosts/README.md) |
| `clusters/` | On-demand Kubernetes labs and manifests. | [clusters/README.md](clusters/README.md) |
| `workstations/` | macOS laptop provisioning and editor settings. | [workstations/README.md](workstations/README.md) |
| `docs/` | Architecture notes and design proposals. | [docs/architecture/README.md](docs/architecture/README.md) |
| `scripts/` | Shared host automation. | [scripts/renew-tailscale-cert.sh](scripts/renew-tailscale-cert.sh) |

## Active host inventory

| Host | Role | Hardware | Platform | IP |
| :--- | :--- | :--- | :--- | :--- |
| `home-nas-server-01` | Primary NAS and container host. | Intel Core i3-9100F, 32 GB RAM, GTX 1060 6 GB. | TrueNAS SCALE. | `192.168.1.69` |
| `home-dns-pi-01` | Network DNS and ad blocking. | Raspberry Pi 3 Model B, 32 GB high endurance SD. | Raspberry Pi OS Lite. | `192.168.1.11` |

## Service catalog

| Stack | Services | Storage tier |
| :--- | :--- | :--- |
| [00-vpn-stack](hosts/home-nas-server-01/stacks/00-vpn-stack/) | Traefik, Tailscale, and Homepage. | `/mnt/fast` |
| [01-media-stack](hosts/home-nas-server-01/stacks/01-media-stack/) | Jellyfin, Radarr, Sonarr, Prowlarr, Bazarr, and qBittorrent. | `/mnt/fast` and `/mnt/media-*` |
| [02-auth-stack](hosts/home-nas-server-01/stacks/02-auth-stack/) | Authelia. | `/mnt/fast` |

Portainer manages all stacks on the TrueNAS host.
The Compose files in this repository are source copies only.
Do not edit a deployed stack from this repository.

## Planned hosts

Two hosts are proposed but not deployed.
See [lab-storage-mac-01](docs/proposals/lab-storage-mac-01.md) and [tl-sg105e-sw-01](docs/proposals/tl-sg105e-sw-01.md).

## Quickstart

- Set up the laptop with [workstations/README.md](workstations/README.md).
- Start the Kubernetes lab with [clusters/README.md](clusters/README.md).
- Deploy or recover the NAS stacks with [hosts/home-nas-server-01/stacks/README.md](hosts/home-nas-server-01/stacks/README.md).

## Rules

All writing follows [rules/writing.md](rules/writing.md).
Agents follow [AGENTS.md](AGENTS.md).

## Hooks

Enable the repository hooks after each clone.

```bash
git config core.hooksPath .githooks
```
