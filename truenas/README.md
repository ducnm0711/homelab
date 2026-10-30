# TrueNAS

This directory holds TrueNAS SCALE design notes and deployment files.

## Architecture

Design documents live in [`architecture/`](architecture/).

- [System architecture](architecture/README.md)
- [Storage pools](architecture/storage.md)
- [Media stack](architecture/media-stack.md)
- [Management SSL](architecture/ssl.md)

## Deployment

Compose stacks, Homepage config, and scripts live in [`deployment/`](deployment/).

- [00-vpn-stack](deployment/00-vpn-stack/): Traefik, Tailscale, and Homepage
- [01-media-stack](deployment/01-media-stack/): Jellyfin and media automation
- [portainer.yaml](deployment/portainer.yaml): Portainer custom app
- [homepage](deployment/homepage/): Homepage service list
- [scripts](deployment/scripts/): Tailscale certificate renewal
