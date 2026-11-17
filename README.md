# Homelab

This repository has three independent parts.
Each part has its own lifecycle and tooling.

| Domain | Purpose | Entry point |
| :--- | :--- | :--- |
| Workstation | Laptop setup, shell, and editor settings. | [workstation/](workstation/README.md) |
| Kubernetes lab | On-demand local Kubernetes lab with k3d. | [k8s-lab/](k8s-lab/README.md) |
| Homelab systems | TrueNAS server and Raspberry Pi server. | [homelab/](homelab/README.md) |

## Workstation

The `workstation/` directory holds the setup for my workstation.
It includes shell configuration, bootstrap scripts, and editor settings.

## Kubernetes lab

The `k8s-lab/` directory holds the on-demand Kubernetes lab.
It uses k3d, Helmfile, Helm charts, SOPS, and raw manifests.

## Homelab systems

The `homelab/` directory holds the physical home systems.
It includes the TrueNAS SCALE server and the Raspberry Pi server.
The TrueNAS server runs Docker Compose stacks behind Traefik and Tailscale.
The Raspberry Pi runs Pi-hole and DNSCrypt-proxy.

## Rules

All writing follows [99-rules/writing.md](99-rules/writing.md).
Agents follow [AGENTS.md](AGENTS.md).
