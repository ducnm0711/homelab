add steps create docker network proxy

docker network create proxy

1/ Install VPN Stack

Manual: Generate cert for Management UI

tailscale cert home-nas-server-01.akita-beaufort.ts.net

2/ Install Media Stack
```
mkdir /mnt/fast/app/[app list]
chown -R 568:568 /mnt/fast/app
```
Bootstrap jellyfin from localhost --> manual update Network - BaseURL /jellyfin
Bootstrap radarr from localhost --> manual update Network - BaseURL /radarr
Bootstrap sonarr from localhost --> manual update Network - BaseURL /sonarr
---
Bootstrap prowlarr from localhost --> manual update new user
Bootstrap qbitorrent from localhost get boostrap session password from log --> manual update new user