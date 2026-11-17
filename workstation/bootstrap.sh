#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WITH_SECRETS=false

usage() {
  echo "Usage: ./bootstrap.sh [--with-secrets]"
  echo "  --with-secrets  Also install age and sops from Brewfile.secrets."
}

while (($#)); do
  case "$1" in
    --with-secrets)
      WITH_SECRETS=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

command -v brew >/dev/null 2>&1 || {
  echo "Homebrew is required. See https://brew.sh." >&2
  exit 1
}

echo "Installing the base packages."
brew bundle --file="${SCRIPT_DIR}/Brewfile"

if [[ "$WITH_SECRETS" == true ]]; then
  echo "Installing the secrets packages."
  brew bundle --file="${SCRIPT_DIR}/Brewfile.secrets"
fi

command -v helm >/dev/null 2>&1 || {
  echo "Helm is required for the Kubernetes lab plugins." >&2
  exit 1
}

plugins="$(helm plugin list)"

install_plugin() {
  local name="$1"
  local url="$2"

  if printf '%s\n' "$plugins" | grep -q "^${name}[[:space:]]"; then
    echo "Helm plugin ${name} is already installed."
    return
  fi

  echo "Installing Helm plugin ${name}."
  helm plugin install "$url" --verify=false
}

install_plugin diff https://github.com/databus23/helm-diff
install_plugin secrets https://github.com/jkroepke/helm-secrets

echo "Bootstrap complete."
echo "See workstation/README.md for the shell and editor configuration."
