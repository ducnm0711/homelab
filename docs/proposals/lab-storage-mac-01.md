# Proposal: lab-storage-mac-01

This document records a planned host.
The host is not deployed.
Do not create a `hosts/lab-storage-mac-01/` folder until the hardware is installed.

## Planned role

The host provides cold media storage and an SMB share.
It is separate from the primary NAS.
A failure on this host does not affect the services on `home-nas-server-01`.

## Planned hardware

| Item | Value |
| :--- | :--- |
| Model | Mac mini 7,1 |
| Processor | Intel Core i5 |
| Memory | 8 GB |
| Storage | 1 TB HDD |
| Platform | macOS with SMB |
| IP address | Reserved |
| Status | Planned |

## Open decisions

- Assign a static IP address before deployment.
- Choose the SMB share names and access groups.
- Decide whether the share uses Time Machine or general media storage.
- Add a host README when the hardware is installed.
