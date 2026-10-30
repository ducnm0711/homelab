# Homelab systems

This directory holds the physical home systems.

## Servers

| Server | Role | Entry point |
| :--- | :--- | :--- |
| TrueNAS | Storage, media, and Docker Compose stacks. | [truenas/](truenas/README.md) |
| Raspberry Pi | Network DNS with Pi-hole and DNSCrypt-proxy. | [raspberry-pi/](raspberry-pi/README.md) |

## Design

TrueNAS separates the management plane from the application plane.
Each plane uses its own Tailscale tailnet.
Applications use path-based routing through Traefik.
The Raspberry Pi uses a small software stack to limit SD card writes.

## Planned

- Add Vaultwarden to the TrueNAS application stack.
- Add Uptime Kuma to the Raspberry Pi.
- Add the Pi-hole admin page to the Tailscale network.
