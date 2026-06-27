# TrueNAS Configuration

## Architecture

Two URL entry points:
- **[truenas-homelab](https://truenas-homelab.akita-beaufort.ts.net)** — TrueNAS webUI, SSL via dedicated Tailscale instance
- **[homelab](https://homelab.akita-beaufort.ts.net)** — reverse proxy for all other apps (Traefik), subdomain/path-based routing

## TrueNAS Apps

| App | Purpose |
|-----|---------|
| **Portainer** | Container management UI for Docker stacks |
| **Tailscale** | Mesh VPN providing secure connectivity |

## Portainer Stacks

### `portainer/` — Traefik Reverse Proxy + Tailscale

**`compose.yml`** — Docker Compose stack with 3 services:

| Service | Image | Purpose |
|---------|-------|---------|
| `tailscale` | `tailscale/tailscale:v1.98.4` | Mesh VPN, exposes `homelab` hostname on tailnet |
| `traefik` | `traefik:v3.7.5` | Reverse proxy, shares network namespace with tailscale |
| `hello` | `nginxdemos/hello` | Test container to verify routing works |

- Traefik runs inside Tailscale's network namespace (`network_mode: "service:tailscale"`)
- All other containers join the external `proxy` network
- Traefik auto-detects containers via Docker provider + file provider

**`dynamic.yaml`** — Traefik dynamic configuration:
- Routes `/dashboard` and `/api` to the Traefik dashboard (basic auth protected)
- TLS via Tailscale cert resolver (`tailscale`)
- (Commented out: path-based Portainer routing to `192.168.1.69:9000`)
