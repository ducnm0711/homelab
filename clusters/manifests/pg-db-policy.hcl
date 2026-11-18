# Read access to the secret data
path "kv/data/pg-db" {
  capabilities = ["read"]
}

# List access to metadata (required for the agent to find/refresh the secret)
path "kv/metadata/pg-db" {
  capabilities = ["list"]
}