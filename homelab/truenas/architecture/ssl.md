# Management SSL

The TrueNAS web UI uses a Tailscale TLS certificate.
The `renew-tailscale-cert.sh` script renews the certificate and binds it to the UI.

## Script

The script is in [../deployment/scripts/renew-tailscale-cert.sh](../deployment/scripts/renew-tailscale-cert.sh).

## Run

```bash
sudo ./renew-tailscale-cert.sh --dry-run
sudo ./renew-tailscale-cert.sh
```

## Behavior

1. The script checks the active UI certificate.
2. It renews the certificate when the expiry is within 15 days.
3. It imports the certificate into TrueNAS.
4. It binds the certificate to the UI.
5. It verifies the certificate served by the UI.
6. It deletes the previous managed certificate.
