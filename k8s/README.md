## Current Setup

### macOS (M4 Pro)

**Current Setup**
- Colima + k3s cluster

**Desired State**
- **Colima** — lightweight Docker-compatible VM (replaces Docker Desktop)
- **k3s** — lightweight Kubernetes distribution for multi-node testing
- **Portainer CE** — web-based UI for managing Docker and Kubernetes

#### Quick Start
```bash
colima start --profile m4 --cpu 6 --memory 12 --disk 100 --arch aarch64 --vm-type vz
colima ssh --profile m4 -- df -h
colima ssh --profile m4 -- free -m
k3d cluster create homelab \
  --agents 2 \
  -p "8080:80@loadbalancer" \
  -p "8443:443@loadbalancer"
```
---

### Windows 11 (AMD Ryzen 5 2600, 32 GB RAM)

**Current Setup**
- Docker Desktop + WSL2

**Desired State**
- **Native Docker Engine inside WSL2 (Ubuntu)** — faster and leaner than Docker Desktop
- **k3s** — lightweight Kubernetes for HA and multi-cluster testing
- **Portainer CE** — unified management dashboard for containers and clusters

---

### Minikube Setup

```bash
colima start --profile m4 --cpu 6 --memory 12 --disk 100 --arch aarch64 --vm-type vz
colima ssh -- df -h
colima ssh -- free -m

minikube start --nodes=3
minikube addons enable ingress
minikube addons enable metrics-server
minikube start --auto-pause-interval=5m
```