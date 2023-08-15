#!/bin/bash

# apt-get install hostapd
# apt-get install dnsmasq
# apt-get install bridge-utils

# INFOS
ssid="tp-link-wn722n"
wpa_passphrase="12345678"
interface="wlan1"
bridge_interface="wlan0"
ipv4="10.1.0" # 192.168.1, 172.16.0

# Configuration file, hostapd WPA2-PSK and CCMP
cat <<EOT > /etc/hostapd/hostapd.conf
interface=$interface
driver=nl80211
ssid=$ssid
hw_mode=g
channel=11
wpa=2
rsn_pairwise=CCMP
wpa_passphrase=$wpa_passphrase
# bridge=br0
EOT

# Configuration file, dnsmasq DHCP and DNS
cat <<EOT > /etc/dnsmasq.conf
interface=$interface
dhcp-range=$ipv4.2,$ipv4.30,255.255.255.0,12h
dhcp-option=3,$ipv4.1
dhcp-option=6,$ipv4.1
server=8.8.8.8
log-queries
log-dhcp
listen-address=127.0.0.1
EOT

# nmcli device disconnect wlan0 # Dissociated interface from any AP
ifconfig $interface up $ipv4.1 netmask 255.255.255.0
echo '1' > /proc/sys/net/ipv4/ip_forward # Enable IP forwarding
echo > /var/lib/misc/dnsmasq.leases # Clear dnsmasq.leases
systemctl restart dnsmasq # Restart DNS/DHCP services

# Setting Rules firewall with iptables 
iptables --flush
iptables --delete-chain
iptables --table nat --flush
iptables --table nat --delete-chain
iptables --table nat -A POSTROUTING -o $bridge_interface -j MASQUERADE
iptables -A FORWARD -i $interface -o $bridge_interface -j ACCEPT

# Starting Access Point
hostapd /etc/hostapd/hostapd.conf
