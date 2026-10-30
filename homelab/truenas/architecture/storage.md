# Storage architecture

This TrueNAS host uses role-based ZFS pools on mixed hardware.
Each pool has one job.
A failure in one pool does not take the other pools with it.

Remote access for applications sits on Tailscale.
That layer is separate from pool design.
See [00-vpn-stack](../deployment/00-vpn-stack) for the application Tailnet and Traefik.

## Pools

### fast

`fast` is the Tier 0 NVMe and SSD pool.
It provides high IOPS.
Use it for container configuration, databases, and local AI weights.

Compose stacks bind application state under `/mnt/fast/app/`.

### junk

`junk` is a staging zone.
Store temporary data that can replaced.
This pool does not need fault tolerance.

### media-01 and media-02

`media-01` and `media-02` are isolated single-disk pools.
This layout is JBOD style.
Do not combine the mismatched hard drives into one ZFS stripe.

If `media-01` fails, the data on `media-02` stays intact.
If `media-02` fails, the data on `media-01` stays intact.
Automation can download the missing media again.

Compose maps `/mnt/media-01` to movies.
Compose maps `/mnt/media-02` to series.
See [01-media-stack](../deployment/01-media-stack).
