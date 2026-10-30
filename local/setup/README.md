# Local setup

Base tooling required on a developer machine before the homelab labs.

## Automated setup

Run the bootstrap script:

```bash
./bootstrap.sh
```

The script installs the Brewfile packages, the Helm plugins, the AGE key, and the k3d clusters.

## Manual setup

Install the tools:

```bash
brew install k3d k9s helm helmfile sops age
```

OrbStack - install via Homebrew (`brew install --cask orbstack`) or download the DMG from https://orbstack.dev.
Launch it, then verify with `orb status`.

Helm plugins:

```bash
helm plugin install https://github.com/databus23/helm-diff
helm plugin install https://github.com/jkroepke/helm-secrets
```

Create k3d clusters:

```bash
k3d cluster create lab-dev
k3d cluster create lab-prd --agents 2
```

Generate an AGE key pair:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Set the key location (add to `~/.zshrc` or `~/.bashrc`):

```bash
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
```
