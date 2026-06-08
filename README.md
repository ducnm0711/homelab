# Lab Infrastructure Documentation

## Kubernetes Lab Profiles
Hybrid management across **macOS (M4 Pro)** via OrbStack + k3d and **Windows 11 (Ryzen 5 2600)** via native WSL2 Ubuntu.

| Profile | Engine | Nodes | Purpose |
| :--- | :--- | :--- | :--- |
| `lab-dev` | k3d | 1 Server | Rapid prototyping and local development. |
| `lab-prd` | k3d | 1+2 Agents | High-availability and multi-node validation. |

```bash
# K3d: Create Lab Environments
k3d cluster create lab-dev
k3d cluster create lab-prd --agents 2

# Start existing cluster
k3d cluster start lab-dev
```

## External Access

Services can be exposed outside the cluster in two ways:

* **Port-forward with k9s (single device):** Quick ad-hoc access for local debugging — `k9s` > select pod > `Ctrl+F` > enter local port. Ideal for one-off access from the host machine.
* **Tailscale (multi-device):** Persistent, secure access across devices using the Tailscale Kubernetes Operator. Annotate a Service with `tailscale.com/expose: "true"` to get an automatic MagicDNS FQDN reachable from any device on your Tailnet.

## Deployment Orchestration (Helmfile)
Use `helmfile.yaml.gotmpl` for modular and environment-aware deployments.

* **Template-Driven Logic:** Uses a default template to dynamically map values and secrets based on directory structure: `configs/{{.Namespace}}/{{.Name}}/{{.Environment}}/values.yaml`.
* **Modular Stacks:** Organized by functional layers:
  - Infra: Cert-manager, OpenBao, Tailscale-operator.
  - Databases: Percona PostgreSQL stack and K8ssandra.
  - Observability: Grafana-operator, Prometheus (Kube-stack), and PMM.
* **Global Defaults:** Namespace controll with `createNamespace: false` and enhanced diffing with `--show-secrets` for tracking state changes.

## Secure Access (Tailscale)
Connectivity via the **Tailscale Kubernetes Operator** to bridge the private Tailnet with internal cluster resources.

* **Service Exposure:** Uses `tailscale.com/expose: "true"` annotations for automatic MagicDNS FQDNs.
* **Cluster Egress:** Maps external Tailnet devices (NAS/Home Servers) to internal `ExternalName` services.
* **Infrastructure:** Operator and Proxy resources deployed in the `infra` namespace using OAuth-based authentication.

## Secret Management (SOPS + AGE)
Secrets are encrypted with **SOPS** using **AGE** keys for simple, local-first secret management.

* **Workflow:** Encrypted YAML files (`secrets.yaml`) live alongside values in `configs/`. Decrypted at deploy time by the `helm-secrets` plugin via Helmfile.
* **Key Setup:** An AGE key pair stored locally (`~/.config/sops/age/keys.txt`) handles all encrypt/decrypt operations — no external infrastructure required.
* **Rotation:** Re-key existing files with `sops updatekeys configs/**/secrets.yaml` when the AGE key changes.
* **OpenBao (planned):** Long-term migration target for dynamic secret injection, replacing static SOPS-encrypted files once the cluster is mature enough to host it reliably.

## TODO: Vaultwarden Deployment
Replace official Bitwarden with a self-hosted **Vaultwarden** (Rust) instance for the home lab.

* **Optimization:** Targeted <128MB RAM footprint for high efficiency.
* **Network Security:** Zero public exposure; access restricted exclusively to the Tailscale network.
* **State Management:** Persistent volume mounts for SQLite/Postgres with automated backup sync to local NAS.
* **Credential Integration:** Use OpenBao to store and rotate the `ADMIN_TOKEN` and database secrets.