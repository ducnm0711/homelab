## Current Setup

### macOS (M4 Pro)

**Current Setup**
- Docker Desktop + Minikube
-> Colima + Minikube
-> Colima + Minikube x3

**Desired State**
- **Colima** — lightweight Docker-compatible VM (replaces Docker Desktop)
- **k3s** — lightweight Kubernetes distribution for multi-node testing
- **Portainer CE** — web-based UI for managing Docker and Kubernetes

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
colima start --cpu 6 --memory 12 --disk 100 --arch aarch64 --vm-type vz
colima ssh -- df -h
colima ssh -- free -m

minikube start --nodes=3
minikube addons enable ingress
minikube addons enable metrics-server
minikube start --auto-pause-interval=5m
```