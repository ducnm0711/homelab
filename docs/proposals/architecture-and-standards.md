# Homelab Repository Architecture & Standards Specification (`ducnm0711/homelab`)

## 1. Core Architectural & Naming Principles
* **KISS (Keep It Simple, Stupid):** Avoid over-engineered IaC abstractions for rarely redeployed personal stacks. Rely on declarative Docker Compose, pinned versions, and embedded documentation.
* **Strict POSIX Kebab-Case:** All directories, hostnames, files, and container aliases use lowercase alphanumeric characters and hyphens (`[a-z0-9-]`).
* **Compute-Tier Taxonomy:** Top-level (first-class) folders use unnumbered plural nouns representing distinct lifecycle and execution domains (`hosts/`, `clusters/`, `workstations/`, `docs/`, `scripts/`). Reserve `00-` numeric prefixes strictly for ordered stacks, chronological ADRs, and sequential execution steps.
* **Standardized Container Conventions:**
  * Canonical Compose filename: `compose.yaml` (never `docker-compose.yml`).
  * Numbered stack prefixes (`00-` through `04-`) to enforce dependency order and visual grouping.
  * Pinned image tags (no `:latest`).
  * Numeric POSIX timezone across all containers: `TZ=Etc/GMT-7`.
* **Zero-Trust & Secret Hygiene:**
  * Plaintext `.env`, `*.age` private keys, SQLite databases, and runtime `appdata/` directories are strictly gitignored.
  * Secrets committed to Git must be encrypted using `sops` + `age` (`secrets.enc.env`).
  * Sanitize all private domains, Tailscale tailnet names, API keys, and tokens before committing.

---

## 2. Complete Directory Tree

```text
ducnm0711/homelab/
├── .github/
│   └── workflows/
│       └── lint-and-validate.yml            # CI: yamllint, docker compose config, gitleaks
│
├── clusters/                                # Kubernetes environments (ephemeral & bare-metal)
│   ├── README.md                            # Spin-up / tear-down guide & cluster comparison
│   ├── k3d-local/                           # Ephemeral laptop cluster (macOS M4/M5 Pro)
│   │   ├── cluster-config.yaml              # k3d port mappings, registries, node counts
│   │   └── bootstrap.sh                     # Cluster creation & Helmfile entrypoint
│   ├── k8s-bare-metal/                      # Future 3-node physical cluster (e.g., Esprimo Q7010)
│   │   ├── inventory/
│   │   │   └── nodes.yaml                   # Control-plane & worker IPs, hardware specs
│   │   └── storage/
│   │       └── truenas-csi-s3.yaml          # External TrueNAS S3 / NFS StorageClass manifests
│   ├── platform/                            # Shared core cluster add-ons
│   │   ├── helmfile.yaml                    # Pinned releases (Envoy Gateway, cert-manager, OpenBao, Velero)
│   │   └── values/
│   │       ├── cert-manager.yaml
│   │       ├── envoy-gateway.yaml
│   │       ├── openbao.yaml
│   │       └── velero.yaml
│   └── workloads/                           # Observability & lab workloads
│       ├── observability/
│       │   ├── helmfile.yaml                # Grafana LGTM stack + Grafana Alloy
│       │   └── values/
│       │       ├── alloy.yaml
│       │       └── loki.yaml
│       └── local-llm/
│           └── ollama-deployment.yaml       # Inference worker manifests
│
├── docs/                                    # Living documentation, diagrams & runbooks
│   ├── adrs/                                # Architecture Decision Records
│   │   ├── 000-template.md
│   │   ├── 001-truenas-single-disk-pools.md
│   │   └── 002-tailscale-traefik-zero-trust.md
│   ├── architecture/
│   │   ├── ipam-and-ports.md                # Static IP table & port registry
│   │   ├── network-topology.md              # Mermaid diagrams (LAN, TL-SG105E, Tailscale)
│   │   └── storage-layout.md                # ZFS pools (fast, media-01, media-02, junk) & mount paths
│   └── runbooks/                            # ASD-STE100 operational & recovery procedures
│       ├── disk-replacement-zfs.md
│       ├── pihole-sd-recovery.md
│       └── truenas-compose-disaster-recovery.md
│
├── hosts/                                   # Persistent 24/7 bare-metal & NAS servers
│   ├── dns-sinkhole-pi-01/                  # Raspberry Pi 3 Model B (192.168.1.11)
│   │   ├── README.md
│   │   ├── dnscrypt-proxy/
│   │   │   └── dnscrypt-proxy.toml          # Encrypted upstream DNS config
│   │   └── pihole/
│   │       ├── pihole.toml                  # Pi-hole v6 config (queryLogging = false)
│   │       └── pihole-ftl.conf              # DBINTERVAL=60.0 SD wear-reduction tuning
│   │
│   ├── home-nas-server-01/                  # TrueNAS SCALE primary server (192.168.1.69)
│   │   ├── README.md
│   │   ├── stacks/
│   │   │   ├── 00-core-ingress/
│   │   │   │   ├── .env.example
│   │   │   │   ├── compose.yaml             # Traefik v3.7, Authelia, Tailscale sidecar
│   │   │   │   ├── README.md
│   │   │   │   └── config/
│   │   │   │       ├── authelia-configuration.yml
│   │   │   │       └── traefik-dynamic.yml
│   │   │   ├── 01-management/
│   │   │   │   ├── .env.example
│   │   │   │   ├── compose.yaml             # Portainer CE 2.45.3, Homepage (gethomepage.dev)
│   │   │   │   ├── README.md
│   │   │   │   └── config/
│   │   │   │       └── homepage/
│   │   │   │           ├── bookmarks.yaml
│   │   │   │           ├── custom.css
│   │   │   │           ├── services.yaml
│   │   │   │           ├── settings.yaml
│   │   │   │           └── widgets.yaml
│   │   │   ├── 02-media-delivery/
│   │   │   │   ├── .env.example
│   │   │   │   ├── compose.yaml             # Jellyfin (GTX 1060 hardware transcoding)
│   │   │   │   └── README.md
│   │   │   ├── 03-media-automation/
│   │   │   │   ├── .env.example
│   │   │   │   ├── compose.yaml             # Radarr, Sonarr, Prowlarr, Bazarr, qBittorrent, Byparr
│   │   │   │   └── README.md
│   │   │   └── 04-knowledge-ai/
│   │   │       ├── .env.example
│   │   │       ├── compose.yaml             # Obsidian Second Brain sync & LightRAG/GraphRAG/MCP
│   │   │       └── README.md
│   │   └── system/
│   │       └── zfs-dataset-map.yaml         # Declarative reference of /mnt/fast & /mnt/media-* paths
│   │
│   └── lab-storage-mac-01/                  # Late-2014 Mac mini 7,1 local media & SMB node
│       ├── README.md
│       └── smb/
│           └── smb.conf.example             # Sanitized SMB share definitions
│
├── scripts/                                 # Shared idempotent automation & guardrails
│   ├── backup-configs.sh                    # Archives sanitized stack configs to cold storage
│   ├── check-health.sh                      # Verifies HTTP/DNS endpoints across hosts
│   └── sops-rotate.sh                       # Encrypts/decrypts *.enc.env files with AGE
│
├── workstations/                            # Personal developer laptop provisioning (macOS)
│   ├── README.md                            # Single-command bootstrap instructions
│   ├── editors/
│   │   ├── cursor/
│   │   │   └── settings.json                # Read-only AI agent guardrails & editor prefs
│   │   └── zed/
│   │       └── settings.json                # Catppuccin Mocha, FiraCode Nerd Font, Vim mode, telemetry off
│   ├── macos/
│   │   ├── Brewfile                         # kubectl, k9s, helmfile, k3d, sops, age, uv, ghostty, zed
│   │   └── defaults.sh                      # Idempotent macOS Dock, Finder, and keyboard tweaks
│   └── shell/
│       ├── .zshrc                           # Oh My Zsh, Starship, fzf, zsh-autosuggestions
│       ├── ghostty-config                   # Ghostty terminal font & theme config
│       └── starship.toml                    # Custom prompt modules (git, kubernetes, context)
│
├── .env.example                             # Global defaults (TZ=Etc/GMT-7, PUID, PGID)
├── .gitignore                               # Ignores .env, *.age, sqlite DBs, runtime appdata/
├── .yamllint.yml                            # 2-space indentation & line-length linting rules
└── README.md                                # Top-level architecture diagram, inventory & navigation
```

---

## 3. Infrastructure Inventory & Storage Baseline

### Network & Host Matrix (`192.168.1.0/24`)
| Hostname | Role | Hardware / Specs | OS / Platform | Static IP |
| :--- | :--- | :--- | :--- | :--- |
| **`home-nas-server-01`** | Primary NAS & Container Host | Intel Core i3-9100F, 32GB RAM, GTX 1060 6GB | TrueNAS SCALE | `192.168.1.69` |
| **`dns-sinkhole-pi-01`** | Network DNS & Ad-Blocking | Raspberry Pi 3 Model B, 32GB High Endurance SD | Raspberry Pi OS Lite | `192.168.1.11` |
| **`lab-storage-mac-01`** | Cold Media & SMB Node | Mac mini 7,1 (Intel Core i5, 8GB RAM, 1TB HDD) | macOS / SMB | Reserved |
| **`tl-sg105e-sw-01`** | Core L2 Managed Switch | TP-Link TL-SG105E 5-Port Gigabit | Managed Firmware | `192.168.1.2` |

### ZFS Storage Tiering (`home-nas-server-01`)
* **`/mnt/fast` (Samsung 970 EVO Plus 500GB NVMe):** Docker runtime, container `appdata` SQLite databases, LightRAG/GraphRAG vector/graph stores, Obsidian vault (`/mnt/fast/knowledge/obsidian-vault`), and transcode cache.
* **`/mnt/media-01`, `/mnt/media-02`, `/mnt/junk` (Single-Disk HDD Pools):** Isolated failure-domain pools (including HGST Ultrastar DC HC310 6TB and WD Purple 1TB) for bulk media and scratch data.

---

## 4. Document Templates

### A. Root `README.md` Blueprint
* **Header Badges:** CI Lint Status, TrueNAS SCALE, Kubernetes (`k3d` | `K8s`), Tailscale Zero-Trust.
* **Mermaid Architecture Diagram:** Visualizes external Tailscale WireGuard ingress -> Traefik v3.7 + Authelia -> `192.168.1.0/24` LAN (`TL-SG105E`, `dns-sinkhole-pi-01`, `home-nas-server-01`, `lab-storage-mac-01`) -> `k3d-local` / bare-metal K8s clusters.
* **Tables:**
  1. Repository Taxonomy (`hosts/`, `clusters/`, `workstations/`, `docs/`, `scripts/`).
  2. Hardware & Compute Inventory.
  3. Service Catalog (`00-` through `04-` stacks with storage tiers).
* **Quickstart Commands:** `brew bundle`, `k3d` bootstrap, and `sops` decryption workflow.
* **Documentation Index:** Direct links to ADRs, IPAM/port registry, ZFS storage layout, and ASD-STE100 runbooks.

### B. Stack-Level `README.md` Contract (`hosts/home-nas-server-01/stacks/<NN-stack-name>/README.md`)
Every stack directory must contain `compose.yaml`, `.env.example`, `README.md`, and an optional `config/` directory. Each stack `README.md` must include:
1. **Metadata Header:** Host (`home-nas-server-01`), Compose file link, Timezone (`TZ=Etc/GMT-7`).
2. **Services & Endpoints Table:** Container name, pinned image tag, network alias, internal port, and Tailscale/Traefik route.
3. **Storage & ZFS Volume Mounts Table:** TrueNAS host path, container path, pool tier (`fast` NVMe vs. `media-*` HDD), and purpose.
4. **Environment Variables Table:** Required variables mapped to `.env.example` / `secrets.enc.env`.
5. **Operations & Recovery Commands:** `docker compose config --quiet`, update command, and ZFS snapshot restore steps.

### C. Architecture Decision Record (ADR) Format (`docs/adrs/NNN-title.md`)
* **Status:** Accepted | Superseded | Deprecated
* **Context:** Infrastructure constraint, failure domain, or operational requirement.
* **Decision:** Chosen architecture or configuration.
* **Consequences:** Trade-offs, blast-radius isolation, security posture, and maintenance impact.

### D. Runbook Format (`docs/runbooks/<topic>.md`)
* Written in **ASD-STE100 (Simplified Technical English)**: short imperative sentences, unambiguous terminology, numbered step-by-step recovery actions, and explicit verification commands.

---

## 5. Agent Implementation Checklist
1. Scaffold top-level directories (`clusters/`, `docs/`, `hosts/`, `scripts/`, `workstations/`, `.github/workflows/`).
2. Migrate existing Compose files into `hosts/home-nas-server-01/stacks/00-` through `04-`, renaming to `compose.yaml`, pinning image tags, and adding `.env.example` + stack `README.md` files.
3. Extract non-secret app configs (Homepage YAML/CSS, Traefik dynamic rules, Authelia config, Pi-hole TOML) into their respective `config/` folders and scrub all secrets/tokens.
4. Create `.gitignore`, `.yamllint.yml`, and `.github/workflows/lint-and-validate.yml` (`gitleaks`, `yamllint`, `docker compose config --quiet`).
5. Populate root `README.md`, `docs/architecture/ipam-and-ports.md`, and initial ADRs/runbooks.
