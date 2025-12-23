# ============================================================================
# Configuration IPv4 - Bypass Livebox Orange
# Mikrotik RouterOS 7.x
# ============================================================================
#
# INSTRUCTIONS :
# 1. Modifiez les valeurs marquées XXXX avec vos propres informations
# 2. Exécutez ce script dans le terminal Mikrotik ou via Winbox
#
# ============================================================================

# ----------------------------------------------------------------------------
# 1. CONFIGURATION DES INTERFACES
# ----------------------------------------------------------------------------
# Adaptez les noms d'interface selon votre routeur

/interface ethernet
set [ find default-name=sfp-sfpplus10 ] name=ether10-WAN comment="WAN-ONU-XGS-PON"
set [ find default-name=sfp-sfpplus12 ] name=ether12-LAN comment="LAN"

# ----------------------------------------------------------------------------
# 2. CRÉATION DU BRIDGE WAN AVEC MAC SPOOFING
# ----------------------------------------------------------------------------
# IMPORTANT : Remplacez XX:XX:XX:XX:XX:XX par l'adresse MAC de votre Livebox
# (visible sur l'étiquette sous la Livebox)

/interface bridge
add name=br-wan admin-mac=XX:XX:XX:XX:XX:XX auto-mac=no protocol-mode=none

# ----------------------------------------------------------------------------
# 3. CONFIGURATION VLAN 832 (INTERNET)
# ----------------------------------------------------------------------------

/interface vlan
add comment="Internet via ONT" interface=ether10-WAN name=vlan832-internet vlan-id=832

# ----------------------------------------------------------------------------
# 4. ASSOCIATION VLAN AU BRIDGE
# ----------------------------------------------------------------------------

/interface bridge port
add bridge=br-wan interface=vlan832-internet

# ----------------------------------------------------------------------------
# 5. FILTRE COS=6 POUR DHCP (OBLIGATOIRE)
# ----------------------------------------------------------------------------
# La priorité COS=6 est requise par le BNG Orange

/interface bridge filter
add action=set-priority chain=output dst-port=67 ip-protocol=udp \
    mac-protocol=ip new-priority=6 out-interface=vlan832-internet \
    passthrough=yes log=yes log-prefix="COS6-DHCPv4"

# ----------------------------------------------------------------------------
# 6. OPTIONS DHCP CLIENT
# ----------------------------------------------------------------------------
# IMPORTANT : Remplacez la valeur de authsend par celle générée sur
# https://jsfiddle.net/kgersen/3mnsc6wy/

/ip dhcp-client option
add code=60 name=vendor-class-identifier value=0x736167656d
add code=77 name=userclass value="0x2b46535644534c5f6c697665626f782e496e7465726e65742e736f66746174686f6d652e4c697665626f7833"
# MODIFIEZ LA LIGNE SUIVANTE avec votre option 90 générée (140 caractères hexa)
add code=90 name=authsend value=0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# ----------------------------------------------------------------------------
# 7. LANCEMENT DU CLIENT DHCP
# ----------------------------------------------------------------------------

/ip dhcp-client
add dhcp-options=hostname,clientid,authsend,userclass,vendor-class-identifier \
    disabled=no interface=br-wan

# ----------------------------------------------------------------------------
# 8. CONFIGURATION IP LAN
# ----------------------------------------------------------------------------

/ip address
add address=192.168.1.1/24 interface=ether12-LAN network=192.168.1.0

# ----------------------------------------------------------------------------
# 9. SERVEUR DHCP LAN
# ----------------------------------------------------------------------------

/ip pool
add name=pool_lan ranges=192.168.1.100-192.168.1.200

/ip dhcp-server
add address-pool=pool_lan disabled=no interface=ether12-LAN lease-time=1w name=LAN

/ip dhcp-server network
add address=192.168.1.0/24 dns-server=8.8.8.8,8.8.4.4 gateway=192.168.1.1 netmask=24

# ----------------------------------------------------------------------------
# 10. NAT
# ----------------------------------------------------------------------------

/ip firewall nat
add action=masquerade chain=srcnat out-interface=br-wan

# ----------------------------------------------------------------------------
# 11. FASTPATH (PERFORMANCE)
# ----------------------------------------------------------------------------

/ip settings
set allow-fast-path=yes

/ip firewall filter
add chain=forward action=fasttrack-connection connection-state=established,related
add chain=forward action=accept connection-state=established,related

# ----------------------------------------------------------------------------
# 12. DÉSACTIVATION SERVICES DANGEREUX
# ----------------------------------------------------------------------------

/ip service
set telnet disabled=yes
set ftp disabled=yes

# ----------------------------------------------------------------------------
# 13. GRAPHING (OPTIONNEL)
# ----------------------------------------------------------------------------

/tool graphing interface add
/tool graphing resource add

# ============================================================================
# FIN DE LA CONFIGURATION IPv4
# Vérifiez que le status du client DHCP est "bound"
# Commande : /ip dhcp-client print detail
# ============================================================================
