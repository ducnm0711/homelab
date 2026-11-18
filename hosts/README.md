# Hosts

This directory holds the physical home systems that run all the time.

| Host | Role | Entry point |
| :--- | :--- | :--- |
| `home-nas-server-01` | Storage, media, and Docker Compose stacks. | [home-nas-server-01/](home-nas-server-01/README.md) |
| `home-dns-pi-01` | Network DNS with Pi-hole and DNSCrypt-proxy. | [home-dns-pi-01/](home-dns-pi-01/README.md) |

## Design

TrueNAS separates the management plane from the application plane.
Each plane uses its own Tailscale tailnet.
Applications use path-based routing through Traefik.
The DNS Pi uses a small software stack to limit SD card writes.

## Planned

- Add Vaultwarden to the TrueNAS application stack.
- Add Uptime Kuma to the DNS Pi.
- Add the Pi-hole admin page to the Tailscale network.
