# ============================================================================
# Configuration Pare-feu IPv4 et IPv6 - Bypass Livebox Orange
# Mikrotik RouterOS 7.x
c
# ============================================================================
#
#
# PRÉREQUIS : Avoir exécuté les configurations IPv4 et IPv6 au préalable
#
# IMPORTANT : Vérifiez que votre réseau LAN est dans la liste "support"
# avant d'activer les règles de blocage
#
# ============================================================================

# ============================================================================
# PARTIE 1 : PARE-FEU IPv4
# ============================================================================

# ----------------------------------------------------------------------------
# 1.1 LISTES D'ADRESSES - SUPPORT (autorisées)
# ----------------------------------------------------------------------------
# Ajoutez TOUS vos réseaux locaux dans cette liste

/ip firewall address-list
add address=192.168.1.0/24 list=support comment="LAN principal"
add address=192.168.42.0/24 list=support comment="LAN TV (si utilisé)"
add address=192.168.88.0/24 list=support comment="LAN config Mikrotik"
add address=192.168.255.0/24 list=support comment="LAN management"

# ----------------------------------------------------------------------------
# 1.2 LISTES D'ADRESSES - BOGONS (invalides depuis WAN)
# ----------------------------------------------------------------------------

/ip firewall address-list
add address=0.0.0.0/8 comment="Self-Identification [RFC 3330]" list=bogons
add address=127.0.0.0/16 comment="Loopback [RFC 3330]" list=bogons
add address=169.254.0.0/16 comment="Link Local [RFC 3330]" list=bogons
add address=192.0.2.0/24 comment="Reserved - IANA - TestNet1" list=bogons
add address=192.88.99.0/24 comment="6to4 Relay Anycast [RFC 3068]" list=bogons
add address=198.18.0.0/15 comment="NIDB Testing" list=bogons
add address=198.51.100.0/24 comment="Reserved - IANA - TestNet2" list=bogons
add address=203.0.113.0/24 comment="Reserved - IANA - TestNet3" list=bogons
# Note: Les plages RFC1918 sont désactivées car utilisées en interne
# add address=10.0.0.0/8 comment="Private[RFC 1918] - CLASS A" disabled=yes list=bogons
# add address=172.16.0.0/12 comment="Private[RFC 1918] - CLASS B" disabled=yes list=bogons
# add address=192.168.0.0/16 comment="Private[RFC 1918] - CLASS C" disabled=yes list=bogons

# ----------------------------------------------------------------------------
# 1.3 RÈGLES PARE-FEU IPv4 - INPUT
# ----------------------------------------------------------------------------

/ip firewall filter

# Protection SYN Flood
add action=add-src-to-address-list address-list=Syn_Flooder \
    address-list-timeout=30m chain=input comment="Detect SYN Flood" \
    connection-limit=30,32 protocol=tcp tcp-flags=syn
add action=drop chain=input comment="Drop SYN Flooder" src-address-list=Syn_Flooder

# Détection Port Scanner
add action=add-src-to-address-list address-list=Port_Scanner \
    address-list-timeout=1w chain=input comment="Detect Port Scanner" \
    protocol=tcp psd=21,3s,3,1
add action=drop chain=input comment="Drop Port Scanner" src-address-list=Port_Scanner

# ICMP
add action=jump chain=input comment="Jump ICMP input" jump-target=ICMP protocol=icmp

# Blocage accès Winbox externe
add action=drop chain=input comment="Block Winbox from WAN" \
    dst-port=8291 protocol=tcp src-address-list=!support

# DNS local
add action=accept chain=input comment="Accept DNS UDP" port=53 protocol=udp
add action=accept chain=input comment="Accept DNS TCP" port=53 protocol=tcp

# Connexions établies/reliées
add action=accept chain=input comment="Accept established" connection-state=established
add action=accept chain=input comment="Accept related" connection-state=related

# Accès depuis réseaux de confiance
add action=accept chain=input comment="Accept from support list" src-address-list=support

# Protection SSH Bruteforce
add action=drop chain=input comment="Drop SSH blacklist" \
    dst-port=22 protocol=tcp src-address-list=ssh_blacklist
add action=add-src-to-address-list address-list=ssh_blacklist \
    address-list-timeout=1w3d chain=input connection-state=new \
    dst-port=22 protocol=tcp src-address-list=ssh_stage3
add action=add-src-to-address-list address-list=ssh_stage3 \
    address-list-timeout=1m chain=input connection-state=new \
    dst-port=22 protocol=tcp src-address-list=ssh_stage2
add action=add-src-to-address-list address-list=ssh_stage2 \
    address-list-timeout=1m chain=input connection-state=new \
    dst-port=22 protocol=tcp src-address-list=ssh_stage1
add action=add-src-to-address-list address-list=ssh_stage1 \
    address-list-timeout=1m chain=input connection-state=new \
    dst-port=22 protocol=tcp

# DROP FINAL - ACTIVER APRÈS AVOIR VÉRIFIÉ LA LISTE SUPPORT
add action=drop chain=input comment="Drop all other input" disabled=no

# ----------------------------------------------------------------------------
# 1.4 RÈGLES PARE-FEU IPv4 - FORWARD
# ----------------------------------------------------------------------------

add action=jump chain=forward comment="Jump ICMP forward" jump-target=ICMP protocol=icmp
add action=drop chain=forward comment="Drop to bogons" dst-address-list=bogons

# Anti-spam
add action=add-src-to-address-list address-list=spammers \
    address-list-timeout=3h chain=forward comment="Detect Spammers" \
    connection-limit=30,32 dst-port=25,587 limit=30/1m,0:packet protocol=tcp
add action=drop chain=forward comment="Drop spammers" \
    dst-port=25,587 protocol=tcp src-address-list=spammers

# SSH bruteforce downstream
add action=drop chain=forward comment="Drop SSH brute downstream" \
    dst-port=22 protocol=tcp src-address-list=ssh_blacklist

# ----------------------------------------------------------------------------
# 1.5 CHAÎNE ICMP
# ----------------------------------------------------------------------------

add action=accept chain=ICMP comment="Echo request (limit)" \
    icmp-options=8:0 limit=1,5:packet protocol=icmp
add action=accept chain=ICMP comment="Echo reply" icmp-options=0:0 protocol=icmp
add action=accept chain=ICMP comment="Time Exceeded" icmp-options=11:0 protocol=icmp
add action=accept chain=ICMP comment="Destination unreachable" icmp-options=3:0-1 protocol=icmp
add action=accept chain=ICMP comment="PMTUD" icmp-options=3:4 protocol=icmp
add action=drop chain=ICMP comment="Drop other ICMP" protocol=icmp

add action=jump chain=output comment="Jump ICMP output" jump-target=ICMP protocol=icmp

# ============================================================================
# PARTIE 2 : PARE-FEU IPv6
# ============================================================================

# ----------------------------------------------------------------------------
# 2.1 LISTES D'ADRESSES IPv6 - BAD
# ----------------------------------------------------------------------------

/ipv6 firewall address-list
add address=::/128 comment="unspecified address" list=bad_ipv6
add address=::1/128 comment="loopback" list=bad_ipv6
add address=fec0::/10 comment="site-local" list=bad_ipv6
add address=::ffff:0.0.0.0/96 comment="ipv4-mapped" list=bad_ipv6
add address=::/96 comment="ipv4 compat" list=bad_ipv6
add address=100::/64 comment="discard only" list=bad_ipv6
add address=2001:db8::/32 comment="documentation" list=bad_ipv6
add address=2001:10::/28 comment="ORCHID" list=bad_ipv6
add address=3ffe::/16 comment="6bone" list=bad_ipv6
add address=::224.0.0.0/100 comment="other" list=bad_ipv6
add address=::127.0.0.0/104 comment="other" list=bad_ipv6
add address=::/104 comment="other" list=bad_ipv6
add address=::255.0.0.0/104 comment="other" list=bad_ipv6

# ----------------------------------------------------------------------------
# 2.2 RÈGLES PARE-FEU IPv6 - INPUT
# ----------------------------------------------------------------------------

/ipv6 firewall filter

# DHCPv6 depuis BNG Orange
add action=accept chain=input dst-port=546 in-interface=br-wan \
    protocol=udp src-address=fe80::ba0:bab/128 comment="DHCPv6 from Orange"

# Connexions établies
add action=accept chain=input comment="Accept established,related,untracked" \
    connection-state=established,related,untracked
add action=drop chain=input comment="Drop invalid" connection-state=invalid

# ICMPv6 (OBLIGATOIRE pour IPv6)
add action=accept chain=input comment="Accept ICMPv6" protocol=icmpv6

# Traceroute UDP
add action=accept chain=input comment="Accept UDP traceroute" \
    port=33434-33534 protocol=udp

# DHCPv6 prefix delegation
add action=accept chain=input comment="Accept DHCPv6-Client PD" \
    dst-port=546 protocol=udp src-address=fe80::/16

# IPsec
add action=accept chain=input comment="Accept IKE" dst-port=500,4500 protocol=udp
add action=accept chain=input comment="Accept IPsec AH" protocol=ipsec-ah
add action=accept chain=input comment="Accept IPsec ESP" protocol=ipsec-esp
add action=accept chain=input comment="Accept IPsec policy" ipsec-policy=in,ipsec

# DROP FINAL - Log pour debug
add action=drop chain=input comment="Drop everything else from WAN" \
    in-interface-list=!LAN log=yes log-prefix="IPv6-DROP"

# ----------------------------------------------------------------------------
# 2.3 RÈGLES PARE-FEU IPv6 - FORWARD
# ----------------------------------------------------------------------------

add action=accept chain=forward comment="Accept established,related,untracked" \
    connection-state=established,related,untracked
add action=drop chain=forward comment="Drop invalid" connection-state=invalid
add action=accept chain=forward comment="Accept ICMPv6" protocol=icmpv6

# Hop limit (équivalent TTL)
add action=drop chain=forward comment="Drop hop-limit=1" hop-limit=equal:1
add action=drop chain=forward comment="Drop src bad_ipv6" src-address-list=bad_ipv6
add action=drop chain=forward comment="Drop dst bad_ipv6" dst-address-list=bad_ipv6

# DROP FINAL FORWARD
add action=drop chain=forward comment="Drop all other forward from WAN" \
    in-interface-list=!LAN log=yes log-prefix="IPv6-FWD-DROP"

# ============================================================================
# PARTIE 3 : LISTE D'INTERFACES
# ============================================================================
# Créez une liste d'interfaces LAN pour simplifier les règles

/interface list
add name=LAN comment="Interfaces LAN internes"

/interface list member
add interface=ether12-LAN list=LAN
# Ajoutez d'autres interfaces LAN si nécessaire
# add interface=ether7-TV list=LAN

# ============================================================================
# VÉRIFICATION
# ============================================================================
# /ip firewall filter print
# /ipv6 firewall filter print
# /ip firewall address-list print
# /ipv6 firewall address-list print
#
# Pour voir les connexions bloquées :
# /log print where topics~"firewall"
# ============================================================================
