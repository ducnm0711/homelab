# Homelab Labs

## 1. Grafana LGTM Stack + Otel Test

Observability stack with Prometheus (metrics), Loki (logs), and Grafana (dashboards). Tempo (traces) and OpenTelemetry collector are not yet deployed — tracked as future additions.

| Service | Namespace | Purpose |
|---|---|---|
| cert-manager | infra | TLS certificates for webhooks |
| rustfs | infra | S3 storage backend for Loki chunks |
| grafana-operator | obs | Manages Grafana CR instances |
| loki | obs | Log aggregation (monolithic mode, S3 backed by rustfs) |
| prometheus | obs | Metrics (kube-prometheus-stack, 1d retention) |
| grafana | obs | Dashboards, datasources, alert rules (via grafana-resources chart) |

## 2. Cassandra NoSQL

Single-node Cassandra 5.0.6 cluster managed by the K8ssandra operator.

| Service | Namespace | Purpose |
|---|---|---|
| cert-manager | infra | TLS webhooks for k8ssandra-operator |
| k8ssandra-operator | dbs | Operator (provides K8ssandraCluster CRD) |
| cassandra (manifest) | dbs | Raw YAML — 1 node, 5Gi, Prometheus metrics enabled |

## 3. Percona PostgreSQL

PostgreSQL 17 cluster with pgBouncer, managed by the Percona PG Operator.

| Service | Namespace | Purpose |
|---|---|---|
| pg-operator | dbs | Percona PG Operator v2.8.0 |
| pg-cluster | dbs | PG 17, 1 HA replica + 1 pgBouncer, 5Gi data volume |
| pmm (optional) | obs | Percona Monitoring & Management (not wired to cluster currently) |

## 4. OpenBao

Secret management (Vault fork) with HA Raft storage, exposed via Tailscale.

| Service | Namespace | Purpose |
|---|---|---|
| openbao | infra | HA (3 replicas, Raft storage), TLS disabled |
| tailscale | infra | Secure external access via Tailscale MagicDNS |

## 5. Velero Backup & Restore

Kubernetes backup/restore with S3-compatible storage. Previously deployed on GKE — needs rework for local k3d clusters.

| Service | Namespace | Purpose |
|---|---|---|
| velero | velero | Velero server (helm chart, not in active helmfile) |
| minio / rustfs | velero / infra | S3-compatible backup target (MinIO 100Gi or RustFS bucket) |
| cert-manager | infra | Webhook TLS for backup targets |
| volume-snapshotclass | cluster | Required for PV snapshots (CSI driver dependent) |

## 6. Percona + OpenBao

OpenBao provides dynamic database credentials for the Percona PostgreSQL cluster via the database secrets engine. The OpenBao agent injector (triggered by `vault.hashicorp.com/*` annotations on the PG pod) fetches short-lived secrets from `secret/data/dbs/pg-operator/users`, and a dedicated sidecar runs `/opt/bao/apply-pg-users.sh` to apply them to the database.
