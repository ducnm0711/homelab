# Lab Infrastructure Documentation

## Kubernetes Lab Profiles
Hybrid management across **macOS (M4 Pro)** via Colima/VZ and **Windows 11 (Ryzen 5 2600)** via native WSL2 Ubuntu.

| Profile | Engine | Nodes | Purpose |
| :--- | :--- | :--- | :--- |
| `lab-dev` | k3d | 1 Server | Rapid prototyping and local development. |
| `lab-prd` | k3d | 1+2 Agents | High-availability and multi-node validation. |
| `lab-prd-lb` | k3d | 1+2 Agents | LoadBalancer testing (Ports 8080/8443). |
| `homelab` | minikube | 3 Nodes | Add-on testing (Metrics-Server, Ingress, Auto-pause). |

```bash
# MacOS: Start Colima VM
colima start --profile m4 --cpu 6 --memory 12 --disk 100 --arch aarch64 --vm-type vz

# K3d: Create Lab Environments
k3d cluster create lab-dev
k3d cluster create lab-prd --agents 2
k3d cluster create lab-prd-lb --agents 2 -p "8080:80@loadbalancer" -p "8443:443@loadbalancer"

# Start existing cluster
k3d cluster start lab-dev
```

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

## Secret Management (OpenBao)
Open-source secret orchestration using **OpenBao** (Vault fork) to manage the lifecycle of cluster credentials.

* **Storage:** KV-V2 engine manages sensitive tokens, including Tailscale OAuth and database credentials.
* **Injection:** Automated sidecar injection via `MutatingWebhookConfiguration` for application pods.
* **Maintenance:** Ownership managed via Helmfile/Server-Side Apply to prevent resource conflicts with legacy `vault-k8s` managers.

## TODO: Vaultwarden Deployment
Replace official Bitwarden with a self-hosted **Vaultwarden** (Rust) instance for the home lab.

* **Optimization:** Targeted <128MB RAM footprint for high efficiency.
* **Network Security:** Zero public exposure; access restricted exclusively to the Tailscale network.
* **State Management:** Persistent volume mounts for SQLite/Postgres with automated backup sync to local NAS.
* **Credential Integration:** Use OpenBao to store and rotate the `ADMIN_TOKEN` and database secrets.