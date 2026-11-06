# TrueNAS deployment

Use these steps to deploy the TrueNAS stacks through Portainer.

## Port policy

Traefik owns the edge inside the Tailscale network namespace.
Traefik listens on ports `80` and `443`.
No application publishes its web UI on a host port.
Each application documents its internal port with `expose`.
Traefik routes each application with the `loadbalancer.server.port` label.

Two exceptions are approved:

- qBittorrent publishes `6881/tcp` and `6881/udp` for torrent peers.
- Portainer uses a temporary host port only for break-glass access.

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

Open each application through its Tailscale route.
The routes use the `home-media.akita-beaufort.ts.net` host.

- Jellyfin: open `/jellyfin`.
- Radarr: open `/radarr`.
- Sonarr: open `/sonarr`.
- Bazarr: open `/bazarr`.
- Prowlarr: open `/prowlarr`, then create a new user.
- qBittorrent: open `/qbittorrent`, read the temporary password from the container log, then create a new user.

The compose file sets the base URL for Jellyfin, Radarr, Sonarr, Bazarr, and Prowlarr.

## 5. Connect the applications

1. Add an indexer in Prowlarr.
2. Copy the API key from Sonarr.
3. Copy the API key from Radarr.
4. Add both API keys to Bazarr.

## Break-glass Portainer access

Use this procedure when the Tailscale route or Traefik is not available.

1. Open the TrueNAS Apps page.
2. Edit the Portainer app.
3. Add the port mapping `9000:9000`.
4. Apply the change.
5. Open `http://<truenas-lan-ip>:9000/portainer/` from the LAN.
6. Repair the affected stack or network.
7. Remove the port mapping.
8. Apply the change again.

This procedure temporarily weakens the zero-port policy.
Remove the mapping after the repair.
