# Proposal: tl-sg105e-sw-01

This document records a planned network device.
The device is not configured.
Do not create a `hosts/tl-sg105e-sw-01/` folder until the device is installed.

## Planned role

The device is the core Layer 2 managed switch.
It connects the NAS, the DNS Pi, and the workstation LAN.
It does not route traffic between networks.

## Planned hardware

| Item | Value |
| :--- | :--- |
| Model | TP-Link TL-SG105E |
| Ports | 5-port Gigabit Ethernet |
| Firmware | Managed firmware |
| IP address | `192.168.1.2` |
| Status | Planned |

## Open decisions

- Record the VLAN layout before deployment.
- Record the port to host mapping in the IPAM document.
- Decide whether 802.1Q VLAN tagging is required.
- Add a host README when the device is installed.
