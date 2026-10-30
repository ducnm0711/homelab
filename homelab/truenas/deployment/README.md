# TrueNAS deployment

Use these steps to deploy the TrueNAS stacks through Portainer.

## 1. Create the proxy network

```bash
docker network create proxy
```

## 2. Install the VPN stack

The VPN stack is in [00-vpn-stack/](00-vpn-stack/).
It runs Traefik and Tailscale.

Generate the certificate for the management UI:

```bash
tailscale cert home-nas-server-01.akita-beaufort.ts.net
```

## 3. Install the media stack

The media stack is in [01-media-stack/](01-media-stack/).
Create the config directories and set the owner to UID/GID 568:

```bash
mkdir -p /mnt/fast/app/{jellyfin,bazarr,radarr,sonarr,prowlarr,qbittorrent}
chown -R 568:568 /mnt/fast/app
```

## 4. Bootstrap the applications

Bootstrap each application from `localhost`.
Then set its base URL.

- Jellyfin: set the base URL to `/jellyfin`.
- Radarr: set the base URL to `/radarr`.
- Sonarr: set the base URL to `/sonarr`.
- Prowlarr: create a new user.
- qBittorrent: read the temporary password from the log, then create a new user.

## 5. Connect the applications

1. Add an indexer in Prowlarr.
2. Copy the API key from Sonarr.
3. Copy the API key from Radarr.
4. Add both API keys to Bazarr.
