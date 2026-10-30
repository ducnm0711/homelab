# Local machines

This directory holds setup for my workstation.
Use it to prepare a new laptop and to run the local Kubernetes labs.

## Layout

- [setup/](setup/README.md): Base tools, Helm plugins, and the AGE key.
- [shell/](shell/README.md): Shell configuration and aliases.
- [k3d/](k3d/README.md): k3d clusters, Helmfile, charts, and manifests.

## Quick start

1. Run the setup steps in [setup/README.md](setup/README.md).
2. Start a k3d cluster. See [k3d/README.md](k3d/README.md).
3. Deploy a lab with Helmfile from `local/k3d`.
