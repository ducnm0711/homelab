# Homelab Repository Summary

This is a homelab infrastructure repository containing:

- **Kubernetes configs** — k3s/k3d/minikube setups for macOS (Colima) and Windows (WSL2)
- **Helm charts** — `pg-db` (PostgreSQL cluster), `grafana-resources` (dashboards, alerts, datasources)
- **Docker Compose** — Percona database setup
- **Observability stack** — Grafana, PMM (Percona Monitoring & Management), Prometheus Blackbox Exporter
- **Infrastructure** — cert-manager, Cassandra, Istio configurations
- **Grafana resources** — dashboards (service-api, http-health, openvpn), alert rules (infrastructure, app-service, backups)

The repo manages a personal home server running on cloud (AWS/GCP) with plans for physical hardware, using GitOps-style infrastructure-as-code.
