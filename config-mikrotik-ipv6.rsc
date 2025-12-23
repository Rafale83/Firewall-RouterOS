# ============================================================================
# Configuration IPv6 - Bypass Livebox Orange
# Mikrotik RouterOS 7.x
# ============================================================================
#
# PRÉREQUIS : Avoir exécuté la configuration IPv4 au préalable
#
# INSTRUCTIONS :
# 1. Modifiez les valeurs marquées XXXX avec vos propres informations
# 2. L'option 11 DOIT être identique à l'option 90 du DHCPv4
# 3. Exécutez ce script dans le terminal Mikrotik
#
# ============================================================================

# ----------------------------------------------------------------------------
# 1. FILTRE COS=6 POUR DHCPv6 (OBLIGATOIRE)
# ----------------------------------------------------------------------------

/interface bridge filter
add chain=output action=set-priority new-priority=6 mac-protocol=ipv6 \
    ip-protocol=udp dst-port=547 out-interface=vlan832-internet \
    log=yes log-prefix="COS6-DHCPv6"

# ----------------------------------------------------------------------------
# 2. PARAMÈTRES IPv6
# ----------------------------------------------------------------------------
# ATTENTION : accept-router-advertisements=no est recommandé pour la sécurité
# (CVE-2023-32154 corrigé depuis RouterOS 7.9.1)

/ipv6 settings
set accept-router-advertisements=no
set allow-fast-path=yes

# ----------------------------------------------------------------------------
# 3. RÈGLE FIREWALL POUR RÉPONSE DHCPv6
# ----------------------------------------------------------------------------
# La requête DHCPv6 part en multicast et revient en unicast
# Sans cette règle, la réponse est bloquée

/ipv6 firewall filter
add chain=input action=accept in-interface=br-wan \
    src-address=fe80::ba0:bab/128 protocol=udp dst-port=546 \
    comment="Accept DHCPv6 reply from Orange BNG"

# ----------------------------------------------------------------------------
# 4. OPTIONS DHCPv6 CLIENT
# ----------------------------------------------------------------------------
# IMPORTANT : L'option 11 (authsend) DOIT être identique à l'option 90 du DHCPv4

/ipv6 dhcp-client option
# Option class-identifier (code 16) = "sagem"
add code=16 name=class-identifier value=0x0000040e0005736167656d

# Option userclass (code 15) = "SVDSL_livebox.Internet.softathome.livebox4"
add code=15 name=userclass value="0x002b46535644534c5f6c697665626f782e496e7465726e65742e736f66746174686f6d652e6c697665626f78340a"

# Option authsend (code 11) - IDENTIQUE à l'option 90 DHCPv4
# MODIFIEZ LA LIGNE SUIVANTE avec votre option générée (140 caractères hexa)
add code=11 name=authsend value=0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# ----------------------------------------------------------------------------
# 5. CLIENT DHCPv6 AVEC DÉLÉGATION DE PRÉFIXE
# ----------------------------------------------------------------------------
# Orange délègue un préfixe /56 (256 sous-réseaux /64 possibles)

/ipv6 dhcp-client
add interface=br-wan \
    dhcp-options=authsend,userclass,class-identifier \
    request=prefix \
    pool-name=pool_FT_6 \
    pool-prefix-length=64 \
    add-default-route=yes \
    disabled=no

# ----------------------------------------------------------------------------
# 6. ANNONCE DU PRÉFIXE IPv6 SUR LE LAN
# ----------------------------------------------------------------------------
# Le premier /64 du pool est annoncé sur l'interface LAN

/ipv6 address
add address=::1/64 from-pool=pool_FT_6 interface=ether12-LAN advertise=yes

# ----------------------------------------------------------------------------
# 7. SERVEUR DHCPv6 (OPTIONNEL)
# ----------------------------------------------------------------------------
# L'autoconfiguration SLAAC fonctionne, mais un serveur DHCPv6 permet
# de distribuer des adresses fixes si nécessaire

/ipv6 dhcp-server
add address-pool=pool_FT_6 name=DHCPv6 interface=ether12-LAN \
    route-distance=5 disabled=no

# ----------------------------------------------------------------------------
# 8. FASTPATH IPv6
# ----------------------------------------------------------------------------

/ipv6 firewall filter
add chain=forward action=fasttrack-connection connection-state=established,related
add chain=forward action=accept connection-state=established,related

# ============================================================================
# VÉRIFICATION
# ============================================================================
# Pour vérifier le préfixe IPv6 délégué :
# /ipv6 pool print detail
# /ipv6 address print detail where interface=ether12-LAN
# /ipv6 dhcp-client print detail
#
# Le préfixe ressemble à : 2a01:cb1d:xxxx:xx00::/56
# ============================================================================
