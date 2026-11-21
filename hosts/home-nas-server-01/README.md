# TrueNAS

This directory holds TrueNAS SCALE design notes and deployment files.

## Architecture

Design documents live in [`docs/architecture/`](../../docs/architecture/).

- [System architecture](../../docs/architecture/README.md)
- [Storage pools](../../docs/architecture/storage.md)
- [Media stack](../../docs/architecture/media-stack.md)
- [Media rules](../../docs/architecture/media-rules.md)
- [Management SSL](../../docs/architecture/ssl.md)

## Deployment

Compose stacks and Homepage config live in [`stacks/`](stacks/).
The Tailscale certificate script lives in [`scripts/`](../../scripts/).

- [00-vpn-stack](stacks/00-vpn-stack/): Traefik, Tailscale, and Homepage.
- [01-media-stack](stacks/01-media-stack/): Jellyfin and media automation.
- [02-auth-stack](stacks/02-auth-stack/): Authelia forward authentication and OIDC.
- [portainer.yaml](stacks/portainer.yaml): Portainer custom app.
- [homepage](stacks/00-vpn-stack/homepage/): Homepage service list.
- [renew-tailscale-cert.sh](../../scripts/renew-tailscale-cert.sh): Tailscale certificate renewal.
