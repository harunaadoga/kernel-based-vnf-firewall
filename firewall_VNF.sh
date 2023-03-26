#!/bin/bash

# iptables variable
ipt="/sbin/iptables"

# network interface names
internal_iface="enp0s8"
external_iface="enp0s3"

# flush existing rules and chains
$ipt -F 
$ipt -t nat -F
$ipt -t mangle -F
$ipt -X
$ipt -t nat -X
$ipt -t mangle -X

# set default policies
$ipt -P INPUT DROP
$ipt -P FORWARD DROP
$ipt -P OUTPUT ACCEPT
$ipt -t nat -P OUTPUT ACCEPT
$ipt -t nat -P PREROUTING ACCEPT
$ipt -t nat -P POSTROUTING ACCEPT

# allow established/related connections
$ipt -A INPUT -i $internal_iface -m state --state ESTABLISHED,RELATED -j ACCEPT

# allow incoming SSH traffic from a specific IP range
$ipt -A INPUT -i $internal_iface -p tcp --dport 22 -m state --state NEW -s 192.168.1.0/24 -j ACCEPT

# allow incoming HTTP/HTTPS traffic from a specific IP range
$ipt -A INPUT -i $internal_iface -p tcp --dport 80 -m state --state NEW -s 192.168.1.0/24 -j ACCEPT
$ipt -A INPUT -i $internal_iface -p tcp --dport 443 -m state --state NEW -s 192.168.1.0/24 -j ACCEPT

# allow outgoing HTTP/HTTPS traffic
$ipt -A OUTPUT -o $external_iface -p tcp --dport 80 -m state --state NEW -j ACCEPT
$ipt -A OUTPUT -o $external_iface -p tcp --dport 443 -m state --state NEW -j ACCEPT

# allow incoming ICMP traffic (ping)
$ipt -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# log and drop all other incoming traffic
$ipt -A INPUT -j LOG --log-prefix "IPT REJECT: "
$ipt -A INPUT -j DROP

# log and drop all other forwarding traffic
$ipt -A FORWARD -j LOG --log-prefix "IPT REJECT: "
$ipt -A FORWARD -j DROP
