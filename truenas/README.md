# System Architecture Document: Secure TrueNAS SCALE 26 & Homelab Deployment

**Target Environment:** TrueNAS SCALE 26 (Docker/Compose-native architecture)  
**Classification:** Internal Infrastructure Design Blueprint  

---

## 1. Executive Summary

This document details a hardened, Zero-Trust network and application architecture blueprint for TrueNAS SCALE 26. The core principle relies on strict isolation of the **Host Management Plane** (`truenas.com`) from the **Application Delivery Plane** (`homelab.com`). 

All ingress and egress traffic is entirely encapsulated inside individual **Tailscale Virtual Private Networks (Tailnets)**. By explicitly avoiding any port exposures to the Local Area Network (LAN) or public internet, the global attack surface is eliminated. The architecture leverages TrueNAS SCALE 26's native Docker backend, allowing deployment of Portable Docker Compose stacks via a central Portainer dashboard.

---

## 2. Goals & Core Objectives

### Objective 1: Double-Tailnet Network Separation
The infrastructure utilizes two completely independent Tailscale instances to guarantee total separation of privileges:
* **Management Tailnet (`truenas.com`):** Bound to the TrueNAS operating system level. Provides exclusive access to the TrueNAS Web GUI and SSH.
* **Homelab Tailnet (`homelab.com`):** Bound to a secure container space. Serves as the sole entry point for all self-hosted user applications.

### Objective 2: Unified Top-Level Domain Namespace & Subpath Routing
To streamline configuration, eliminate external DNS complexity, and bypass wildcard subdomain tracking, the architecture enforces a path-based routing design:
* Only **two** global entry points are valid (`https://truenas.com` and `https://homelab.com`).
* All self-hosted user applications are multiplexed off the application root domain via unique subpaths (e.g., `/portainer`, `/grafana`, `/gitea`). No unique subdomains are created.

### Design Principles
* **Vendor Abstraction:** Native TrueNAS Apps are restricted to core middleware dependencies (Tailscale only). 
* **Container Portability:** Applications are managed as pure Docker Compose deployments inside Portainer.
* **Edge Hardening:** No application containers expose raw network ports to the LAN or local host. The external perimeter firewall blocks all incoming WAN ports (No Port Forwarding).

---

## 3. High-Level Architecture Diagrams

### 3.1 Network Topology & Perimeter Routing

    ```text
      Internet / Tailscale VPN Cloud
                   │
          ┌────────┴────────┐
          │                 │
      Tailnet A         Tailnet B
     (truenas.com)     (homelab.com)
          │                 │
          │                 │
    Native Tailscale    Traefik Proxy
    (TrueNAS App)      (Network Anchor)
          │                 │
          ▼                 │
    +──────────────+        │
    │ TrueNAS GUI  │    Docker Tailscale
    │ (Web UI/SSH) │  (joins via network_mode:
    +──────────────+   "service:traefik")
                            │
                  ┌─────────┼─────────┐
                  │         │         │
                  ▼         ▼         ▼
              /portainer /grafana   /gitea
                  │         │         │
              Portainer  Grafana    Gitea
    ```

    **Tailnet A — Management Tailscale (Native TrueNAS App):**
    Bound to the TrueNAS OS. Handles admin access to the TrueNAS Web GUI and SSH at `https://truenas.com`.

    **Tailnet B — App Tailscale (Traefik Proxy + Tailscale Container):**
    Traefik is the **network anchor** attached to the `proxy` bridge. The Tailscale container joins Traefik's network namespace via `network_mode: "service:traefik"`, sharing the same network stack and exposing Traefik directly on the Tailnet at `https://homelab.com`.

---

## 4. Layered System Architecture

The environment is cleanly partitioned into four operational tiers. If any layer fails, the layers underneath remain unaffected:

* **Layer 0: Core Operating System**
    * TrueNAS SCALE 26 (ZFS Storage Engine, Native Docker Runtime Environment).
* **Layer 1: Host Control & Core Management Orchestrators**
    * **Native Tailscale App:** Connects the physical host directly to the Management Tailnet (`truenas.com`).
    * **Portainer (Custom App):** Initialized with full access to `/var/run/docker.sock` to act as the primary interface for Compose deployments.
* **Layer 2: App Ingress & Traffic Management Routing**
    * **Homelab Tailscale Container:** Embedded sidecar providing an entry point to the application layer (`homelab.com`).
    * **Traefik Proxy:** Attached directly to the Homelab Tailscale network instance. Evaluates all path prefixes and manages SSL routing.
* **Layer 3: Isolated Application Workloads**
    * Application stacks broken down logically by context (Monitoring, Media, Development, and Core Infrastructure).

---

## 5. Application Orchestration Ecosystem

### 5.1 Native Apps Configuration
Only one official application package is permitted inside the TrueNAS cluster manager:
* **Application:** Tailscale
* **Objective:** Resolves `https://truenas.com`. Maps directly to host network ports `80` and `443` to give administrators remote access to the TrueNAS Web UI and SSH.

### 5.2 Custom Apps Configuration
Only one management application is initialized through the TrueNAS Advanced Custom App menu:
* **Application:** Portainer CE
* **Objective:** Direct container daemon control. Used to launch, update, and manage all subsequent Docker Compose stacks listed below.

---

## 6. Portainer Stacks (Compose Definitions)

The infrastructure is modularized into four distinct, self-contained `compose.yaml` files.

### 6.1 Core Infrastructure Stack
This stack deploys the application Tailscale edge node and binds Traefik directly to its network space, allowing Traefik to intercept inbound requests securely.

    ```yaml
    version: '3.8'
    
    services:
      tailscale-app:
        image: tailscale/tailscale:stable
        container_name: tailscale-homelab-ingress
        hostname: homelab
        environment:
          - TS_AUTHKEY=tskey-auth-sampleKeyHere-ephemeral
          - TS_EXTRA_ARGS=--advertise-tags=tag:homelab-apps
          - TS_STATE_DIR=/var/lib/tailscale
        volumes:
          - /mnt/tank/data/traefik/tailscale:/var/lib/tailscale
          - /dev/net/tun:/dev/net/tun
        cap_add:
          - NET_ADMIN
          - SYS_MODULE
        networks:
          - homelab-public
        restart: unless-stopped
    
      traefik:
        image: traefik:v3.0
        container_name: traefik-core-proxy
        # Essential Pattern: Uses the Tailscale container's network layer directly
        network_mode: "service:tailscale-app"
        depends_on:
          - tailscale-app
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock:ro
          - /mnt/tank/data/traefik/traefik.yml:/etc/traefik/traefik.yml:ro
        restart: unless-stopped
    
    networks:
      homelab-public:
        external: true
    ```

### 6.2 Other Stacks (Monitoring, Development, Media)

All app services follow the same label pattern. Here is the generic template:

```yaml
services:
  <service>:
    image: <image>:<tag>
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.<name>.rule=Host(`homelab.com`) && PathPrefix(`/<path>`)"
      - "traefik.http.routers.<name>.entrypoints=websecure"
      - "traefik.http.middlewares.<name>-strip.stripprefix.prefixes=/<path>"
      - "traefik.http.routers.<name>.middlewares=<name>-strip"
      - "traefik.http.services.<name>.loadbalancer.server.port=<port>"
```

| Stack      | Service  | Image                              | Path         | Port |
|------------|----------|------------------------------------|--------------|------|
| Monitoring | Grafana  | `grafana/grafana:latest`           | `/grafana`   | 3000 |
| Development| Gitea    | `gitea/gitea:latest`               | `/gitea`     | 3000 |
| Media      | Immich   | `immich-app/immich-server:release` | `/immich`    | 2283 |
| Media      | Jellyfin | `jellyfin/jellyfin:latest`         | `/jellyfin`  | 8096 |

---

## 7. Network Architecture & Traffic Flow

To isolate cross-container communications, the Docker network space is segmented into two distinct software bridge interfaces:

1.  **`homelab-public` (External Edge Network):** Connects the Homelab Tailscale interface container directly to the Traefik core load balancer. No application containers are allowed here.
2.  **`homelab-private` (Internal Transit Mesh):** Connects Traefik backend interfaces to all private application layers. 

### Data Flow Pattern
When an authenticated remote client makes a request to a homelab app, the traffic flows through the following network steps:

    ```text
    [Remote User App Request]
             │
             ▼
    [Tailscale VPN Decryption]
             │
             ▼
     [homelab-public Bridge]
             │
             ▼
      [Traefik Ingress Proxy] (Evaluates /path context & Strips Path Base)
             │
             ▼
     [homelab-private Bridge]
             │
             ▼
       [Target Container] (e.g., Grafana, Immich, Gitea)
    ```

---

## 8. Storage & File System Layout

All configuration state details, runtime application data, and raw storage elements are decoupled from the containers and stored in structured ZFS datasets inside the primary storage pool (`tank/`):

    ```text
    tank/
    ├── apps/                          # Structural Operational Frameworks
    │   ├── compose/                   # Versioned Docker Compose files
    │   ├── configs/                   # Global configuration profiles
    │   └── backups/                   # System state snapshots
    │
    ├── data/                          # Persistent Application Data Volumes
    │   ├── portainer/                 # Portainer execution data
    │   ├── traefik/                   # Traefik logs and static configs
    │   ├── grafana/                   # Dashboard indices and SQLite files
    │   ├── gitea/                     # Git repositories and accounts
    │   ├── immich/                    # Processed photos and indexes
    │   └── ...
    │
    └── media/                         # High-Capacity Media Datasets
        ├── movies/
        └── tv/
    ```

---

## 9. Security Compliance Policy

To maintain a Zero-Trust profile, this architecture enforces the following security compliance rules:

* **Zero-Port Bindings:** Do not use host port bindings (`ports: - "X:Y"`) inside any container compose files. Containers must communicate purely over private, virtual Docker networks (`homelab-private`).
* **Perimeter Lockdown:** Ports `80`, `443`, `3000`, `8080`, `9090`, and `9443` must remain closed on your home router. No port forwarding rules or DMZ configurations are permitted.
* **Encapsulation Enforcement:** All ingress traffic must pass through the encrypted native or containerized Tailscale adapters. If a client disconnects from the Tailnet, access to both the management and application planes is blocked instantly.

---

## 10. Operational Benefits

* **Total Management Isolation:** The TrueNAS administrative dashboard operates independently. If the Docker runtime or the Traefik reverse proxy crashes, storage access and web management via `truenas.com` remain functional.
* **Clean Single-Domain Namespace:** Path-based mapping removes the need to configure split-horizon DNS, manage individual Tailscale subdomains, or register separate MagicDNS aliases for every application.
* **Infrastructure Portability:** By leveraging native Docker Compose stacks instead of proprietary app formats, your entire homelab setup can be easily backed up, versioned via Git, and migrated to any alternative Docker-compatible system if needed.
* **Frictionless Scaling:** Deploying a new application is simplified to adding the container service to a Compose stack, assigning it to the `homelab-private` network, and adding the required Traefik subpath routing labels.