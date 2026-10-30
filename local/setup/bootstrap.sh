#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v brew >/dev/null 2>&1 || {
  echo "Homebrew is required." >&2
  exit 1
}

brew bundle --file="${SCRIPT_DIR}/Brewfile"

helm plugin list | grep -q '^diff' || helm plugin install https://github.com/databus23/helm-diff
helm plugin list | grep -q '^secrets' || helm plugin install https://github.com/jkroepke/helm-secrets

mkdir -p "$HOME/.config/sops/age"
if [[ ! -f "$HOME/.config/sops/age/keys.txt" ]]; then
  age-keygen -o "$HOME/.config/sops/age/keys.txt"
fi

k3d cluster list | grep -q '^lab-dev' || k3d cluster create lab-dev
k3d cluster list | grep -q '^lab-prd' || k3d cluster create lab-prd --agents 2

echo "Add this to your shell profile:"
echo 'export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"'
