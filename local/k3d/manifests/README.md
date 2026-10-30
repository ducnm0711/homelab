Raw YAML manifest

bao secrets enable database
bao auth enable kubernetes
bao write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
bao read auth/kubernetes/config
bao write auth/kubernetes/role/dbs-pg-operator \
    bound_service_account_names="pg-db-instance" \
    bound_service_account_namespaces="dbs" \
    policies="dbs-pg-operator" \
    ttl=24h