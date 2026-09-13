# Raspberry Pi 3 Setup Guide

## 1. Introduction
This document shows the setup instructions for the Raspberry Pi 3. The system uses a small software stack. This configuration decreases data writes to increase the life of the SD card.

## 2. Hardware and Operating System Setup
Use these steps when an SD card reader is not available. The objective is to install Raspberry Pi OS (Lite) on the SD card.

1. Download the Rufus software and the Raspberry Pi OS (Lite) image.
2. Use Rufus to write the Raspberry Pi OS (Lite) image to a USB flash drive.
3. Start the Raspberry Pi 3 from the USB flash drive.
4. Insert the SD card into the Raspberry Pi 3.
5. Find the device names for the USB flash drive and the SD card. Type this command:
   `lsblk`
6. Copy the data from the USB flash drive to the SD card. Type this command (Change `sda` to your USB drive and `mmcblk0` to your SD card):
   `sudo dd if=/dev/sda of=/dev/mmcblk0 bs=4M status=progress`
7. Wait for the copy operation to complete. Type this command to make sure all data writes to the SD card:
   `sync`
8. Turn off the Raspberry Pi 3. Type this command:
   `sudo poweroff`
9. Remove the USB flash drive.
10. Start the Raspberry Pi 3 from the SD card.

## 3. Software Setup
The Raspberry Pi 3 has limited resources. The software stack must be small. We use an old SD card. You must keep the data footprint small to save the SD card life.

### 3.1 CLI Guide
Use the command-line interface (CLI) to configure the network.

#### 3.1.1 Connection Steps
1. Connect to a wireless network (WLAN). Type this command (Change `YourSSID` and `YourPassword` to your network data):
   `sudo nmcli device wifi connect "YourSSID" password "YourPassword"`
2. Set a static IP address. Type this command (Change `YourSSID` and `192.168.1.100/24` to your network data):
   `sudo nmcli connection modify "YourSSID" ipv4.addresses 192.168.1.100/24 ipv4.method manual`
3. Set the gateway IP address. Type this command (Change `192.168.1.1` to your router IP address):
   `sudo nmcli connection modify "YourSSID" ipv4.gateway 192.168.1.1`
4. Set the DNS server. Type this command:
   `sudo nmcli connection modify "YourSSID" ipv4.dns 1.1.1.1`
5. Restart the network connection. Type this command:
   `sudo nmcli connection up "YourSSID"`

#### 3.1.2 Connection Preference
You can use a wireless network or a wired network. The user chooses the network type. This setup uses a wireless network.

### 3.2 Core Services

#### 3.2.1 Pi-hole
Install Pi-hole for network-wide DNS management.
1. Change the database configuration to decrease write operations on the SD card.
2. Open the Pi-hole configuration file. Type this command:
   `sudo nano /etc/pihole/pihole-FTL.conf`
3. Add or change these lines to optimize data retention and the write interval:
   `MAXDBDAYS=90`
   `DBINTERVAL=60`
4. Save the file and restart the Pi-hole service. Type this command:
   `sudo systemctl restart pihole-FTL`

#### 3.2.2 DNSCrypt-proxy
Install DNSCrypt-proxy to encrypt DNS traffic. This software helps to bypass ISP domain blocks.
1. Follow the instructions in the official guide: https://docs.pi-hole.net/guides/dns/dnscrypt-proxy/

#### 3.2.3 Tailscale
Install Tailscale. Tailscale gives secure network access. It also gives HTTPS access to the Pi-hole web user interface.

## 4. Client Setup

### 4.1 Windows
Windows clients have a DNS problem. The system queries the IPv6 DNS server first. This action causes the connection to fail. 
1. Open the network adapter settings.
2. Disable the IPv6 protocol.
3. Try the connection again.

### 4.2 MacOS
MacOS clients do not have this problem. 
1. Update the DNS list in the network settings.
2. Connect to the network.

## 5. To Do
* **Health Checks**: Install Uptime Kuma to monitor system health.
* **Dashboard Integration**: Add the Pi-hole administration user interface into Tailscale and the DevHome overview board.
* **Network-wide Protection**: Explore how to force all home network devices to use Pi-hole automatically. Investigate if it is necessary to update the DNS configuration in the ISP modem or router.

## 6. Optional Steps
Use these command-line instructions to configure additional system settings.

### 6.1 Enable SSH
1. Start the SSH service. Type this command:
   `sudo systemctl start ssh`
2. Enable the SSH service to start automatically. Type this command:
   `sudo systemctl enable ssh`

### 6.2 Set Vim as Default Editor
1. Install Vim. Type this command:
   `sudo apt install vim`
2. Configure the default system editor. Type this command:
   `sudo update-alternatives --config editor`
3. Type the selection number for Vim and press Enter.