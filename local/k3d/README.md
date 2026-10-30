# k3d labs

This directory holds the local Kubernetes labs.
The labs run on k3d on macOS (OrbStack) or Windows 11 (WSL2).

## Profiles

| Profile | Engine | Nodes | Purpose |
| :--- | :--- | :--- | :--- |
| `lab-dev` | k3d | 1 server | Rapid prototyping and local development. |
| `lab-prd` | k3d | 1 server + 2 agents | High-availability and multi-node validation. |

```bash
k3d cluster create lab-dev
k3d cluster create lab-prd --agents 2
k3d cluster start lab-dev
```

## Layout

- `helmfile.yaml.gotmpl`: Release definitions and the default template.
- `environments.yaml`: Environment to kube-context mapping.
- `charts/`: Local Helm charts and repository definitions.
- `configs/`: Per-release values and SOPS-encrypted secrets.
- `manifests/`: Raw YAML manifests and helper scripts.

## Deployment

Run Helmfile from this directory.

```bash
helmfile -e dev list
helmfile -e dev diff
helmfile -e dev apply
```

The default template maps values by directory:

```text
configs/{{Namespace}}/{{Name}}/values.yaml
configs/{{Namespace}}/{{Name}}/{{Environment}}/values.yaml
```

It maps secrets the same way:

```text
configs/{{Namespace}}/{{Name}}/secrets.yaml
configs/{{Namespace}}/{{Name}}/{{Environment}}/secrets.yaml
```

## External access

- Port-forward with k9s: quick ad-hoc access for one device.
- Tailscale: persistent access across devices.

Annotate a Service with `tailscale.com/expose: "true"` to get a MagicDNS name.

## Secrets

Secrets use SOPS with AGE.
The `.sops.yaml` file at the repository root sets the key.

```bash
sops updatekeys configs/**/secrets.yaml
```

## Labs

### 1. Grafana LGTM stack and OpenTelemetry test

Observability stack with Prometheus (metrics), Loki (logs), and Grafana (dashboards).
Tempo (traces) and the OpenTelemetry collector are not yet deployed.
They are tracked as future additions.

| Service | Namespace | Purpose |
|---|---|---|
| cert-manager | infra | TLS certificates for webhooks |
| rustfs | infra | S3 storage backend for Loki chunks |
| grafana-operator | obs | Manages Grafana CR instances |
| loki | obs | Log aggregation (monolithic mode, S3 backed by rustfs) |
| prometheus | obs | Metrics (kube-prometheus-stack, 1d retention) |
| grafana | obs | Dashboards, datasources, alert rules (via grafana-resources chart) |

### 2. Cassandra NoSQL

Single-node Cassandra 5.0.6 cluster managed by the K8ssandra operator.

| Service | Namespace | Purpose |
|---|---|---|
| cert-manager | infra | TLS webhooks for k8ssandra-operator |
| k8ssandra-operator | dbs | Operator (provides K8ssandraCluster CRD) |
| cassandra (manifest) | dbs | Raw YAML, 1 node, 5Gi, Prometheus metrics enabled |

### 3. Percona PostgreSQL

PostgreSQL 17 cluster with pgBouncer, managed by the Percona PG Operator.

| Service | Namespace | Purpose |
|---|---|---|
| pg-operator | dbs | Percona PG Operator |
| pg-cluster | dbs | PG 17, 1 HA replica + 1 pgBouncer, 5Gi data volume |
| pmm (optional) | obs | Percona Monitoring and Management (not wired to the cluster currently) |

### 4. OpenBao

Secret management (Vault fork) with HA Raft storage, exposed via Tailscale.

| Service | Namespace | Purpose |
|---|---|---|
| openbao | infra | HA (3 replicas, Raft storage), TLS disabled |
| tailscale | infra | Secure external access via Tailscale MagicDNS |

### 5. Velero backup and restore

Kubernetes backup and restore with S3-compatible storage.
This lab was previously deployed on GKE.
It needs rework for local k3d clusters.

| Service | Namespace | Purpose |
|---|---|---|
| velero | velero | Velero server (Helm chart, not in the active Helmfile) |
| minio / rustfs | velero / infra | S3-compatible backup target (MinIO 100Gi or RustFS bucket) |
| cert-manager | infra | Webhook TLS for backup targets |
| volume-snapshotclass | cluster | Required for PV snapshots (CSI driver dependent) |

### 6. Percona and OpenBao

OpenBao provides dynamic database credentials for the Percona PostgreSQL cluster through the database secrets engine.
The OpenBao agent injector reads the `vault.hashicorp.com/*` annotations on the PG pod.
It fetches short-lived secrets from `secret/data/dbs/pg-operator/users`.
A dedicated sidecar runs `/opt/bao/apply-pg-users.sh` to apply them to the database.
