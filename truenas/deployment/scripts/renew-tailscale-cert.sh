#!/usr/bin/env bash
# ==============================================================================
# Script: renew-tailscale-cert.sh
# Purpose: Renew a Tailscale TLS certificate and bind it to the TrueNAS 27 GUI.
# ==============================================================================

set -Eeuo pipefail
umask 077

# --- Configuration & Defaults ---
NAS_CERT="${NAS_CERT:-home-nas-server-01.akita-beaufort.ts.net}"
TAILSCALE_CONTAINER="${TAILSCALE_CONTAINER:-ix-tailscale-tailscale-1}"
DAYS_THRESHOLD="${DAYS_THRESHOLD:-15}"
GUI_PORT="${GUI_PORT:-443}"
GUI_CONNECT_HOST="${GUI_CONNECT_HOST:-${NAS_CERT}}"
GUI_VERIFY="${GUI_VERIFY:-1}"
VERIFY_TIMEOUT="${VERIFY_TIMEOUT:-45}"
DRY_RUN="${DRY_RUN:-0}"
FORCE_RENEW="${FORCE_RENEW:-0}"

log()  { printf '[%s] [INFO] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
warn() { printf '[%s] [WARN] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
err()  { printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
die()  { err "$*"; exit 1; }

usage() {
  cat <<USAGE
Usage: $0 [OPTIONS]
  -n, --dry-run       Fetch and validate certificate; do not modify TrueNAS
  -f, --force         Renew regardless of active certificate expiry
  -d, --days N        Renew when expiry is within N days (default: ${DAYS_THRESHOLD})
  -h, --help          Show this help
USAGE
}

while (($#)); do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    -f|--force) FORCE_RENEW=1; shift ;;
    -d|--days)
      (($# >= 2)) || die "--days requires a value"
      DAYS_THRESHOLD="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

for cmd in midclt docker jq openssl date mktemp flock timeout; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command missing: $cmd"
done

# Prevent overlapping runs
LOCK_FILE="/var/run/renew-tailscale-cert.lock"
if ! exec 9>"$LOCK_FILE"; then
  LOCK_FILE="/tmp/renew-tailscale-cert.lock"
  exec 9>"$LOCK_FILE"
fi
flock -n 9 || { warn "Another renewal process is already running; exiting." ; exit 0; }

TMP_DIR="$(mktemp -d /tmp/ts-cert.XXXXXX)"
CONTAINER_TMP="/tmp/ts-cert-$(date +%s)-$$"
CONTAINER_TMP_CREATED=0

cleanup() {
  if (( CONTAINER_TMP_CREATED )); then
    docker exec "$TAILSCALE_CONTAINER" rm -rf -- "$CONTAINER_TMP" >/dev/null 2>&1 || true
  fi
  rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT

if [[ "$DRY_RUN" == 1 ]]; then
  log "DRY-RUN enabled: no TrueNAS certificate/configuration changes will be made."
fi

# 1. Check Active TrueNAS UI Certificate
log "Checking active TrueNAS UI certificate..."
GENERAL_CONFIG="$(midclt call system.general.config)" || die "Unable to read system.general.config"
ACTIVE_CERT_ID="$(jq -r '.ui_certificate // empty' <<<"$GENERAL_CONFIG")"
ACTIVE_CERT_OBJ=""
NEEDS_RENEWAL=0

if [[ "$FORCE_RENEW" == 1 ]]; then
  warn "Force enabled; skipping active certificate expiry check."
  NEEDS_RENEWAL=1
elif [[ -z "$ACTIVE_CERT_ID" || "$ACTIVE_CERT_ID" == "null" ]]; then
  warn "No active UI certificate configured; renewal required."
  NEEDS_RENEWAL=1
else
  ACTIVE_CERT_OBJ="$(midclt call certificate.get_instance "$ACTIVE_CERT_ID" 2>/dev/null || true)"
  CERT_PEM="$(jq -r '.certificate // empty' <<<"${ACTIVE_CERT_OBJ:-{}}" 2>/dev/null || true)"
  
  if [[ -z "$CERT_PEM" ]]; then
    warn "Active certificate ID ${ACTIVE_CERT_ID} is missing PEM data; renewal required."
    NEEDS_RENEWAL=1
  elif ! openssl x509 -in <(printf '%s' "$CERT_PEM") -checkend "$((DAYS_THRESHOLD * 86400))" -noout >/dev/null 2>&1; then
    EXPIRY_DATE="$(openssl x509 -in <(printf '%s' "$CERT_PEM") -noout -enddate | cut -d= -f2)"
    warn "Active certificate expires within ${DAYS_THRESHOLD} days (expiry: ${EXPIRY_DATE}); renewal required."
    NEEDS_RENEWAL=1
  else
    EXPIRY_DATE="$(openssl x509 -in <(printf '%s' "$CERT_PEM") -noout -enddate | cut -d= -f2)"
    log "Active certificate is valid beyond ${DAYS_THRESHOLD} days (expiry: ${EXPIRY_DATE}); nothing to do."
    exit 0
  fi
fi

(( NEEDS_RENEWAL == 1 )) || exit 0

# 2. Generate New Certificate via Tailscale Container
log "Checking Tailscale container '${TAILSCALE_CONTAINER}'..."
CONTAINER_RUNNING="$(docker inspect -f '{{.State.Running}}' "$TAILSCALE_CONTAINER" 2>/dev/null || echo "false")"
[[ "$CONTAINER_RUNNING" == "true" ]] || die "Tailscale container is not running or not found: ${TAILSCALE_CONTAINER}"

log "Generating Tailscale certificate for ${NAS_CERT}..."
docker exec "$TAILSCALE_CONTAINER" mkdir -p "$CONTAINER_TMP"
CONTAINER_TMP_CREATED=1
docker exec "$TAILSCALE_CONTAINER" tailscale cert \
  --cert-file="${CONTAINER_TMP}/tls.crt" \
  --key-file="${CONTAINER_TMP}/tls.key" \
  "$NAS_CERT" || die "tailscale cert failed inside ${TAILSCALE_CONTAINER}"

docker cp "${TAILSCALE_CONTAINER}:${CONTAINER_TMP}/tls.crt" "$TMP_DIR/tls.crt"
docker cp "${TAILSCALE_CONTAINER}:${CONTAINER_TMP}/tls.key" "$TMP_DIR/tls.key"

# Validate certificate output
openssl x509 -in "$TMP_DIR/tls.crt" -noout >/dev/null || die "Generated certificate is not valid PEM"
openssl pkey -in "$TMP_DIR/tls.key" -noout >/dev/null || die "Generated private key is invalid"

CERT_PUBKEY_HASH="$(openssl x509 -in "$TMP_DIR/tls.crt" -pubkey -noout | openssl pkey -pubin -outform DER | sha256sum | awk '{print $1}')"
KEY_PUBKEY_HASH="$(openssl pkey -in "$TMP_DIR/tls.key" -pubout -outform DER | sha256sum | awk '{print $1}')"
[[ "$CERT_PUBKEY_HASH" == "$KEY_PUBKEY_HASH" ]] || die "Certificate and private key do not match"

NEW_EXPIRY="$(openssl x509 -in "$TMP_DIR/tls.crt" -noout -enddate | cut -d= -f2)"
NEW_SUBJECT="$(openssl x509 -in "$TMP_DIR/tls.crt" -noout -subject -nameopt RFC2253 | cut -d= -f2-)"
NEW_FINGERPRINT="$(openssl x509 -in "$TMP_DIR/tls.crt" -noout -fingerprint -sha256 | cut -d= -f2)"
# Shortened name to prevent string length limits
NEW_CERT_NAME="tailscale-${NAS_CERT%%.*}-$(date +%Y%m%d%H%M%S)"

log "Validated certificate: subject=${NEW_SUBJECT}; expiry=${NEW_EXPIRY}; sha256=${NEW_FINGERPRINT}"

if [[ "$DRY_RUN" == 1 ]]; then
  log "DRY-RUN: certificate generated and validated; no TrueNAS changes performed."
  exit 0
fi

# 3. Import and Apply to TrueNAS
log "Importing certificate into TrueNAS as '${NEW_CERT_NAME}'..."
PAYLOAD="$(jq -n \
  --rawfile cert "$TMP_DIR/tls.crt" \
  --rawfile key "$TMP_DIR/tls.key" \
  --arg name "$NEW_CERT_NAME" \
  '{name:$name, certificate:$cert, privatekey:$key, create_type:"CERTIFICATE_CREATE_IMPORTED"}')"

CREATE_RESPONSE="$(midclt call --job certificate.create "$PAYLOAD")" || die "TrueNAS certificate.create job failed: $CREATE_RESPONSE"
NEW_CERT_ID="$(echo "$CREATE_RESPONSE" | jq -r '.id // empty')"

if [[ -z "$NEW_CERT_ID" || "$NEW_CERT_ID" == "null" ]]; then
  die "Failed to parse new certificate ID from job response: $CREATE_RESPONSE"
fi
log "Imported certificate successfully with TrueNAS Cert ID: ${NEW_CERT_ID}."

log "Binding new certificate to TrueNAS UI..."
UPDATE_PAYLOAD="$(jq -n --argjson id "$NEW_CERT_ID" '{ui_certificate:$id}')"
midclt call system.general.update "$UPDATE_PAYLOAD" >/dev/null || {
  midclt call certificate.delete "$NEW_CERT_ID" >/dev/null 2>&1 || true
  die "system.general.update failed; new certificate removed"
}

log "Restarting Web UI service via system.general.ui_restart..."
# TrueNAS 27 UI restart mechanism (takes an integer for delay in seconds)
midclt call system.general.ui_restart 1 >/dev/null || warn "Failed to trigger UI restart automatically; UI may require manual refresh."

# 4. Verify GUI Application
if [[ "$GUI_VERIFY" == 1 ]]; then
  log "Verifying certificate served by ${GUI_CONNECT_HOST}:${GUI_PORT}..."
  VERIFIED=0
  DEADLINE=$((SECONDS + VERIFY_TIMEOUT))
  
  while (( SECONDS <= DEADLINE )); do
    SERVED_FINGERPRINT="$(timeout 8 openssl s_client \
      -connect "${GUI_CONNECT_HOST}:${GUI_PORT}" \
      -servername "$NAS_CERT" -showcerts </dev/null 2>/dev/null |
      openssl x509 -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2 || true)"
      
    if [[ -n "$SERVED_FINGERPRINT" && "${SERVED_FINGERPRINT//:/}" == "${NEW_FINGERPRINT//:/}" ]]; then
      VERIFIED=1
      break
    fi
    sleep 3
  done
  
  if (( VERIFIED == 0 )); then
    warn "GUI did not serve the new certificate within ${VERIFY_TIMEOUT}s."
  else
    log "New certificate verification successful."
  fi
else
  warn "GUI_VERIFY=0: skipping served-certificate verification."
fi

# 5. Cleanup Old Certificates
if [[ -n "$ACTIVE_CERT_ID" && "$ACTIVE_CERT_ID" != "$NEW_CERT_ID" ]]; then
  OLD_NAME="$(jq -r '.name // empty' <<<"${ACTIVE_CERT_OBJ:-{}}" 2>/dev/null || true)"
  if [[ "$OLD_NAME" == tailscale-* ]]; then
    log "Deleting previous managed Tailscale certificate '${OLD_NAME}' (ID ${ACTIVE_CERT_ID})..."
    midclt call certificate.delete "$ACTIVE_CERT_ID" >/dev/null || warn "Could not delete old certificate ID ${ACTIVE_CERT_ID}."
  else
    log "Keeping previous certificate '${OLD_NAME}' because it is not managed by this script."
  fi
fi

log "Tailscale certificate renewal completed successfully."
exit 0