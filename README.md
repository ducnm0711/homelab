# Homelab

This repository has two independent parts.
Each part has its own lifecycle and tooling.

| Domain | Purpose | Entry point |
| :--- | :--- | :--- |
| Local machines | Laptop setup, shell, and k3d labs. | [local/](local/README.md) |
| Homelab systems | TrueNAS server and Raspberry Pi server. | [homelab/](homelab/README.md) |

## Local machines

The `local/` directory holds the setup for my workstation.
It includes shell configuration, bootstrap scripts, and the k3d Kubernetes labs.
The labs use Helmfile, Helm charts, SOPS, and raw manifests.

## Homelab systems

The `homelab/` directory holds the physical home systems.
It includes the TrueNAS SCALE server and the Raspberry Pi server.
The TrueNAS server runs Docker Compose stacks behind Traefik and Tailscale.
The Raspberry Pi runs Pi-hole and DNSCrypt-proxy.

## Rules

All writing follows [rules/writing.md](rules/writing.md).
Agents follow [AGENTS.md](AGENTS.md).
