02/02/2026 - Update the helm 4 + helmfile 1.2.3

```
brew upgrade helm
brew upgrade helmfile
helm plugin install https://github.com/databus23/helm-diff --verify=false
helm plugin install https://github.com/jkroepke/helm-secrets/releases/download/v4.7.5/secrets-4.7.5.tgz --verify=false
helm plugin install https://github.com/jkroepke/helm-secrets/releases/download/v4.7.5/secrets-getter-4.7.5.tgz --verify=false
helm plugin install https://github.com/jkroepke/helm-secrets/releases/download/v4.7.5/secrets-post-renderer-4.7.5.tgz --verify=false
```