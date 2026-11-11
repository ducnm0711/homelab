# TrueNAS deployment

Use these steps to deploy the TrueNAS stacks through Portainer.

## Port policy

Traefik owns the edge inside the Tailscale network namespace.
Traefik listens on ports `80` and `443`.
No application publishes its web UI on a host port.
Each application documents its internal port with `expose`.
Traefik routes each application with the `loadbalancer.server.port` label.

Two exceptions are approved:

- qBittorrent publishes `6881/tcp` and `6881/udp` for torrent peers.
- Portainer uses a temporary host port only for break-glass access.

## 1. Create the proxy network

```bash
docker network create proxy
```

## 2. Install the VPN stack

The VPN stack is in [00-vpn-stack/](00-vpn-stack/).
It runs Traefik and Tailscale.

Generate the certificate for the management UI:

```bash
tailscale cert home-nas-server-01.akita-beaufort.ts.net
```

### Add temporary setup basic auth

Use basic auth during setup.
Do not use Authelia until the media stack works.

Create a password hash for the `setup` user:

```bash
docker run --rm httpd:alpine htpasswd -nbB setup 'your-password'
```

Add the middleware to `/mnt/fast/app/traefik/dynamic.yaml`:

```yaml
http:
  middlewares:
    setup-auth:
      basicAuth:
        users:
          - "setup:$2y$..."
```

The repository files use `authelia@docker` for the final state.
Replace it with `setup-auth@file` during setup.

Before you deploy the VPN stack, change the Homepage router middleware to `setup-auth@file`.
Change the Traefik dashboard router in `/mnt/fast/app/traefik/dynamic.yaml` to `setup-auth@file`.
Add `setup-auth@file` to the Portainer router before `portainer-strip`.

Keep `setup-auth@file` on Jellyfin and Portainer until their SSO work is complete.
Remove `setup-auth` and the `setup` user only after that work is complete.

## 3. Install the media stack with basic auth

The media stack is in [01-media-stack/](01-media-stack/).
Create the config directories and set the owner to UID/GID 568:

```bash
mkdir -p /mnt/fast/app/{jellyfin,bazarr,radarr,sonarr,prowlarr,qbittorrent}
chown -R 568:568 /mnt/fast/app
```

Before you deploy the media stack, set these router middlewares to `setup-auth@file`:

- Radarr.
- Sonarr.
- Bazarr.
- Jellyfin.

Keep the native login for each application during setup.
Do not set `External` or `None` yet.

Prowlarr and qBittorrent are LAN only.
Use their native login.
Do not add a Traefik route for them.

## 4. Bootstrap the applications

Open the protected applications through their Tailscale route.
The routes use the `home-media.akita-beaufort.ts.net` host.
Enter the `setup` basic auth credentials first.
Then sign in to the application.

- Homepage: open `/`.
- Traefik dashboard: open `/dashboard/`.
- Radarr: open `/radarr`.
- Sonarr: open `/sonarr`.
- Bazarr: open `/bazarr`.
- Jellyfin: open `/jellyfin`.
- Portainer: open `/portainer/`.

Create a user in each application.
Set the application passwords and preferences now.

Open the LAN-only applications from the LAN:

- Prowlarr: open `http://homelab.local:9696`.
- qBittorrent: open `http://homelab.local:8080`.
  Read the temporary password from the container log, then create a new user.

The compose file sets the base URL for Jellyfin and Bazarr.

## 5. Connect the applications

1. Add an indexer in Prowlarr.
2. Copy the API key from Sonarr.
3. Copy the API key from Radarr.
4. Add both API keys to Bazarr.

Verify indexer search, downloads, imports, subtitles, and playback.
Continue to the auth stack only after the media stack works.

## 6. Install the auth stack

The auth stack is in [02-auth-stack/](02-auth-stack/).
It runs Authelia as a Traefik forward-auth provider.

Create the config and secrets directories:

```bash
mkdir -p /mnt/fast/app/authelia/secrets
```

Copy the config files:

```bash
cp 02-auth-stack/configuration.yml /mnt/fast/app/authelia/configuration.yml
cp 02-auth-stack/users.yml /mnt/fast/app/authelia/users.yml
```

Generate the session secret, the storage key, and the OIDC HMAC secret:

```bash
openssl rand -hex 32 > /mnt/fast/app/authelia/secrets/session_secret
openssl rand -hex 32 > /mnt/fast/app/authelia/secrets/storage_key
openssl rand -hex 32 > /mnt/fast/app/authelia/secrets/hmac_secret
```

Set the owner to UID/GID 568 and restrict the secret files:

```bash
chown -R 568:568 /mnt/fast/app/authelia
chmod 600 /mnt/fast/app/authelia/secrets/*
```

The `configuration.yml` file reads the HMAC secret from `secrets/hmac_secret`.
The `configuration.yml` file uses the `secret` template function.
The Authelia service must set this environment variable:

```yaml
X_AUTHELIA_CONFIG_FILTERS: template
```

Generate a password hash for each user:

```bash
docker run --rm authelia/authelia:4.39 authelia crypto hash generate argon2 --password 'your-password'
```

Add the digest and the user details to `/mnt/fast/app/authelia/users.yml`.
Set the user groups for Jellyfin access:

```yaml
groups: [admins, jellyfin-users]
```

The `jellyfin-users` group is the normal Jellyfin login role.
The `admins` group is the Jellyfin admin role.
Do not commit secrets to git.

Deploy `02-auth-stack` as a Portainer stack.
The setup basic auth still protects the Tailscale routes.
Open `/auth` and confirm that the Authelia portal works.

Authelia serves its portal at `/auth`.
The access control rule bypasses `/auth`.
All other paths require one-factor authentication.
A session lasts 12 hours.
A session expires after 2 hours of inactivity.

For each protected request, Authelia sends these headers to the application:

- `Remote-User`
- `Remote-Groups`
- `Remote-Email`
- `Remote-Name`

## 7. Roll out SSO

Authelia is the single sign-on gate at Traefik.
An application joins single sign-on when its Traefik router uses `authelia@docker`.
The forward-auth middleware redirects an unauthenticated request to `/auth`.
After login, Authelia sends the user headers to the application.

| Application | Route | Setup gate | Final gate | Application login |
| :--- | :--- | :--- | :--- | :--- |
| Homepage | `/` | Basic auth | Authelia | None |
| Traefik dashboard | `/dashboard/` | Basic auth | Authelia | None |
| Radarr | `/radarr` | Basic auth | Authelia | External |
| Sonarr | `/sonarr` | Basic auth | Authelia | External |
| Bazarr | `/bazarr` | Basic auth | Authelia | None |
| Jellyfin | `/jellyfin` | Basic auth | SSO Authentication plugin | Authelia via SSO Authentication |
| Prowlarr | LAN only | Native LAN login | Native LAN login | Native |
| qBittorrent | LAN only | Native LAN login | Native LAN login | Native |
| Portainer | `/portainer/` | Basic auth | `[TO-DO]` SSO | Native until SSO |

Switch one route at a time.
Use this order:

1. Homepage.
2. Traefik dashboard.
3. Radarr.
4. Sonarr.
5. Bazarr.

For each route:

1. Confirm that the route works with basic auth.
2. Change the middleware to `authelia@docker`.
3. Confirm that the route redirects to `/auth`.
4. Sign in with the Authelia user.
5. Confirm that the application loads.

Do not change Jellyfin or Portainer in this step.
Keep the `setup-auth@file` middleware on both.
Complete section 8 before you remove the setup gate from Jellyfin.

### Radarr and Sonarr

Radarr and Sonarr use `External` authentication after the Authelia gate works.
This mode disables the application login.
The Authelia gate does the login check.

1. Verify that Authelia blocks the route:

   ```bash
   curl -s -o /dev/null -w '%{http_code}\n' https://home-media.akita-beaufort.ts.net/radarr
   ```

   The command returns `302` or `401`.
2. Stop the container.
3. Open `/mnt/fast/app/<app>/config.xml`.
4. Set these values:

   ```xml
   <Config>
     <AuthenticationMethod>External</AuthenticationMethod>
     <AuthenticationRequired>Enabled</AuthenticationRequired>
   </Config>
   ```

5. Start the container.

Do not set `External` until the Authelia gate works.
Without the gate, the application login is open.

### Bazarr

Bazarr does not need its own login because Authelia protects the route.

1. Open `Settings > General > Authentication`.
2. Set `Authentication` to `None`.

### Prowlarr and qBittorrent

Prowlarr and qBittorrent are LAN only.
They keep their native login.
No Authelia rule protects them.
Do not set `External` authentication for these applications.

### API clients

Authelia protects the full application route.
An internal application reaches another application by container name.
This traffic does not pass through Traefik.
An external API client that uses the Tailscale route is blocked by Authelia.
If the client cannot use a session cookie, add a separate router for the API path.
Use a higher priority for the API router.
Do not add the `authelia@docker` middleware to the API router.

## 8. SSO for Jellyfin

Jellyfin uses the SSO Authentication plugin from the [K0lin repository](https://github.com/K0lin/jellyfin-plugin-sso).
The plugin version is `5.1.1`.
Plugin version 5.1 and later requires Jellyfin 12.0 or later.
The media stack runs Jellyfin 12.3.
The 9p4 manifest currently serves version `4.0.0.4` for Jellyfin 10.11.
Do not use the 9p4 manifest with Jellyfin 12.3.
Keep the `setup` basic auth gate until the SSO login works.

### Prepare the Authelia OIDC client

The Authelia OIDC client is in `02-auth-stack/configuration.yml`.
The client ID is `jellyfin`.
The redirect URI is `https://home-media.akita-beaufort.ts.net/jellyfin/sso/OID/redirect/authelia`.
The client requests the `openid`, `profile`, `email`, and `groups` scopes.
The client uses `client_secret_post` for token endpoint authentication.
The access control bypass list in `configuration.yml` must include `^/jellyfin(/.*)?$`.
The bypass lets the SSO plugin start the Authelia login flow.

Generate the OIDC signing key and the client secret:

```bash
openssl genpkey -algorithm RSA -out /mnt/fast/app/authelia/secrets/oidc.pem -pkeyopt rsa_keygen_bits:4096
openssl rand -hex 32 > /mnt/fast/app/authelia/secrets/jellyfin_client_secret
chown 568:568 /mnt/fast/app/authelia/secrets/oidc.pem /mnt/fast/app/authelia/secrets/jellyfin_client_secret
chmod 600 /mnt/fast/app/authelia/secrets/oidc.pem /mnt/fast/app/authelia/secrets/jellyfin_client_secret
```

Do not use a short or simple client secret.

Deploy or restart `02-auth-stack`.
Confirm that Authelia starts without errors:

```bash
docker logs authelia
```

Confirm that Authelia serves the discovery document:

```bash
curl -fsS https://home-media.akita-beaufort.ts.net/auth/.well-known/openid-configuration
```

### Install the SSO Authentication plugin

1. Open the Jellyfin dashboard.
2. Open `Plugins > Repositories`.
3. Add this repository URL:

   ```text
   https://raw.githubusercontent.com/k0lin/jellyfin-plugin-sso/manifest-release/manifest.json
   ```

4. Open `Plugins > Catalog`.
5. Install `SSO Authentication` version `5.1.1`.
6. Restart Jellyfin.
7. Confirm that `/mnt/fast/app/jellyfin/plugins/SSO-Auth` is owned by UID/GID 568.

### Configure the Authelia provider

1. Open `Dashboard > Plugins` and select the `SSO Authentication` settings page.
2. Add a provider with these values:

   | Field | Value |
   | :--- | :--- |
   | Name of OpenID Provider | `authelia` |
   | OpenID Endpoint | `https://home-media.akita-beaufort.ts.net/auth` |
   | OpenID Client ID | `jellyfin` |
   | OpenID client secret | The contents of `jellyfin_client_secret` |
   | Enabled | Checked |
   | Enable Authorization by Plugin | Checked |
   | Enable All Folders | Checked |
   | Roles | `jellyfin-users` |
   | Admin Roles | `admins` |
   | Preserve Existing Admin Permissions | Checked |
   | Role Claim | `groups` |
   | OIDC Scopes | `groups` |
   | Disable Pushed Authorization (Insecure) | Checked if Authelia logs a method mismatch |
   | Scheme Override | `https` |

   The provider name `authelia` must match the last part of the Authelia redirect URI.
   Leave `Enable Authorization by Plugin` unchecked at first if an existing administrator account is not protected.
   A plugin login can overwrite the permissions of an account with the same name.
   Enable `Preserve Existing Admin Permissions` before you enable plugin authorization.
   The `Disable Pushed Authorization (Insecure)` option may be needed for Authelia.
   Enable it if Authelia logs a method mismatch between the push request and the token request.

3. Save the settings.
4. Restart Jellyfin.

### Add the login button

1. Open `Dashboard > General`.
2. Open `Branding`.
3. Put this text in the `Login disclaimer` field:

   ```html
   <a href="/jellyfin/sso/OID/start/authelia">Sign in with Authelia</a>
   ```

4. Save the settings.

The provider name in the URL must match `authelia`.

### Test the login

1. Open a private browser window.
2. Open `https://home-media.akita-beaufort.ts.net/jellyfin`.
3. Click `Sign in with Authelia`.
4. Sign in with the Authelia user.
5. Click `Accept`.
6. Confirm that Jellyfin opens with your user.
7. Confirm that the local Jellyfin administrator login still works.
8. Link an existing Jellyfin user at `/jellyfin/SSOViews/linking` if the plugin creates a second account.

### After the test

Set `log.level` back to `info` if you changed it.
Keep the local Jellyfin administrator account for recovery.
Do not put secrets in git.

### Remove the setup gate

Remove `setup-auth@file` from the Jellyfin router if it is present.
Do not add `authelia@docker` to the Jellyfin router.
The SSO Authentication plugin handles the login.
Keep the `^/jellyfin(/.*)?$` bypass rule in the Authelia access control list.
The bypass lets the plugin redirect to Authelia without a second forward-auth gate.

Remove the `setup` user only after Jellyfin and Portainer both use SSO.

### Troubleshooting

- `invalid_client`: The client secret in the plugin does not match `jellyfin_client_secret`.
- `redirect_uri` error: The redirect URI does not match the Authelia client configuration.
- Pushed authorization error: Enable `Disable Pushed Authorization (Insecure)`.
- Method mismatch: Authelia reports a method mismatch between the push request and the token request.
  Enable `Disable Pushed Authorization (Insecure)` and save.
- Discovery error: Enable `Do Not Validate OpenID Endpoints (Insecure)`.
- Jellyfin cannot reach Authelia: Check the DNS alias or the `extra_hosts` entry.
- Login loop: Check the `/jellyfin` bypass rule and remove any forward-auth middleware from the Jellyfin router.

## 9. [TO-DO] SSO for Portainer

Portainer keeps the `setup` basic auth gate until SSO is ready.
Portainer needs an Authelia OIDC client.
Add the client to the Authelia identity provider configuration.
Remove the `setup` user only after the Portainer SSO login works.

## Break-glass Portainer access

Use this procedure when the Tailscale route or Traefik is not available.

1. Open the TrueNAS Apps page.
2. Edit the Portainer app.
3. Add the port mapping `9000:9000`.
4. Apply the change.
5. Open `http://<truenas-lan-ip>:9000/portainer/` from the LAN.
6. Repair the affected stack or network.
7. Remove the port mapping.
8. Apply the change again.

This procedure temporarily weakens the zero-port policy.
Remove the mapping after the repair.
