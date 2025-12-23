# Bypass Livebox Orange : Connexion Fibre Directe sur Routeur

> **Guide complet pour se connecter à la fibre Orange sans Livebox, jusqu'à 8 Gbps symétrique en XGS-PON**

## Avertissement préalable

⚠️ **Ce tutoriel s'adresse aux utilisateurs avancés** disposant des compétences techniques nécessaires et du matériel adéquat.

**Cette manipulation est inutile si vous ne disposez pas :**
- D'un réseau local multigigabit (10 Gbps minimum)
- De machines suffisamment puissantes pour exploiter ces débits
- D'un routeur capable de gérer le débit souhaité avec les règles de pare-feu

**Sans infrastructure adaptée, vous n'exploiterez pas la bande passante disponible.**

---

## Table des matières

1. [Introduction et contexte](#introduction-et-contexte)
2. [Prérequis matériels](#prérequis-matériels)
3. [Choix de l'ONU selon votre offre](#choix-de-lonu-selon-votre-offre)
4. [Configuration de l'ONU WAS-110 (XGS-PON)](#configuration-de-lonu-was-110-xgs-pon)
5. [Extraction des identifiants Orange](#extraction-des-identifiants-orange)
6. [Génération des options DHCP](#génération-des-options-dhcp)
7. [Configuration du routeur - IPv4](#configuration-du-routeur---ipv4)
8. [Configuration du routeur - IPv6](#configuration-du-routeur---ipv6)
9. [Configuration du pare-feu](#configuration-du-pare-feu)
10. [Vérification et dépannage](#vérification-et-dépannage)
11. [Sources et remerciements](#sources-et-remerciements)

---

## Introduction et contexte

### Pourquoi bypasser la Livebox ?

Les Livebox Orange, même récentes, présentent des limitations :
- **Livebox 6** : port 2.5 Gbps mais pas de vrai mode bridge
- **Livebox 7** : performances bridées par le matériel intégré
- Impossibilité de personnaliser le routage, le pare-feu, les VLANs

### Technologies PON chez Orange

| Technologie | Débit descendant | Débit montant | Livebox associée |
|-------------|------------------|---------------|------------------|
| **GPON** | 2.5 Gbps | 1.2 Gbps | Livebox 5/6 |
| **XGS-PON** | 10 Gbps | 10 Gbps | Livebox 7 |

### Les états PLOAM (O1 à O5)

Lors de l'inscription d'un ONU sur le réseau PON Orange, celui-ci passe par plusieurs états :

| État | Nom | Description |
|------|-----|-------------|
| **O1** | Initial | L'ONU est démarré, cherche un signal OLT |
| **O2** | Standby | Signal détecté, attente de ranging |
| **O3** | Serial Number | L'ONU envoie son numéro de série |
| **O4** | Ranging | Synchronisation temporelle avec l'OLT |
| **O5** | Operation | ✅ **État nominal** - ONU pleinement opérationnel |

**L'objectif est d'atteindre l'état O5** (ou O5.1 sur les affichages détaillés).

---

## Prérequis matériels

### Routeur compatible

Le routeur doit supporter :
- Interfaces SFP+ ou 10GBaseT
- VLAN tagging
- Client DHCPv4/DHCPv6 avec options personnalisées
- COS/802.1p priority tagging

**Routeurs recommandés (Mikrotik) :**
- **CCR2004-1G-12S+2XS** (12 ports SFP+ 10G) - ~595€
- **CCR2116-12G-4S+** 
- **CCR2216-1G-12XS-2XQ**

### Switch 10 Gbps (si nécessaire)

- **Mikrotik CRS305-1G-4S+in** (4 ports SFP+) - ~147€
- **Mikrotik CRS309-1G-8S+** (8 ports SFP+) - ~252€

### ONU/ONT selon votre offre

Voir section suivante pour le choix de l'ONU adapté.

---

## Choix de l'ONU selon votre offre

### Offres GPON (jusqu'à 2 Gbps) - Livebox 5/6

**Module recommandé : FS.COM GPON-ONU-34-20BI**
- Chipset Intel/Lantiq PEB98035
- Mode HSGMII 2.5 Gbps
- Prix : ~70€
- Lien : https://www.fs.com/fr/products/133619.html

### Offres XGS-PON (5 Gbps et plus) - Livebox 7

**Module recommandé : WAS-110**
- Chipset MaxLinear PRX126  
- Interface 10 Gbps native
- Firmware communautaire 8311 très actif
- Support et documentation excellents

**Où acheter le WAS-110 :**
- [FiberMall](https://www.fibermall.com/sale-462134-xgspon-onu-sfp-stick-i-temp.htm)
- [AliExpress (version 8311)](https://www.aliexpress.us/item/1005007856556526.html) - choisir "8311 Version"
- Délai de livraison : 4-6 jours

**Alternatives XGS-PON :**
| Modèle | Chipset | Fabricant | Lien |
|--------|---------|-----------|------|
| XGS-ONU-25-20NI | CIG XG-99S | FS.com | [fs.com](https://www.fs.com/fr/products/185594.html) |
| LXE-010X-A | Realtek RTL9615C | Leox | [leolabs.pl](https://www.leolabs.pl/ont-leox-lxe-010x-a.html) |

⚠️ **Seuls ces trois modèles sont compatibles avec Orange XGS-PON.**

---

## Configuration de l'ONU WAS-110 (XGS-PON)

### Installation du firmware 8311

Si votre WAS-110 n'est pas pré-flashé avec le firmware 8311 :

1. **Connecter le WAS-110** à un port SFP+ compatible (switch, NIC, media converter)

2. **Accéder à l'interface** : http://192.168.11.1
   - Login : `root`
   - Password : par défaut vide ou `root`

3. **Flasher le firmware 8311** via SSH :

```bash
# Télécharger le firmware (depuis un PC)
wget https://github.com/djGrrr/8311-was-110-firmware-builder/releases/latest/download/WAS-110_8311_firmware_mod_<version>_basic.7z

# Extraire
7z e '-i!local-upgrade.*' WAS-110_8311_firmware_mod_<version>_basic.7z -o/tmp

# Transférer et installer
scp -O -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa /tmp/local-upgrade.tar root@192.168.11.1:/tmp/
ssh -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa root@192.168.11.1 'tar xvf /tmp/local-upgrade.tar -C /tmp/ -- upgrade.sh && /tmp/upgrade.sh -y -r /tmp/local-upgrade.tar'
```

### Récupération des identifiants Livebox 7

Avant de configurer le WAS-110, récupérez les informations de votre Livebox 7 :

1. Accédez à https://livebox/ (mot de passe : 12 premiers caractères de la clé WiFi)
2. Allez dans **Paramètres avancés** → **Informations système** → **ONT**
3. Notez :
   - **Serial Number** : `SMBSXXXXXXXX` (obligatoire)
   - **ONT Software Version 0** : ex. `SAHEOFR010117`
   - **ONT Software Version 1** : ex. `SAHEOFR919117`
   - Vérifiez que **Max Bit Rate Supported** = `10000Mbps`

### Configuration du WAS-110

**Via l'interface web** (recommandé) :

1. Accédez à https://192.168.11.1/cgi-bin/luci/admin/8311/config

2. Onglet **PON**, configurez :

| Paramètre | Valeur | Obligatoire |
|-----------|--------|-------------|
| PON Serial Number (ONT ID) | `SMBSXXXXXXXX` | ✅ |
| Equipment ID | `SagemcomFast5694OFR` | Non |
| Hardware Version | `SMBSXLB7400` (LB7 v1) ou `SMBSXLB7270200` (LB7 v2) | ✅ |
| Sync Circuit Pack Version | ✅ (coché) | ✅ |
| Software Version A | `SAHEOFR010117` | Recommandé |
| Software Version B | `SAHEOFR919117` | Recommandé |
| MIB File | `/etc/mibs/prx300_1U.ini` | ✅ |

3. Onglet **ISP Fixes** : désactivez **Fix VLANs**

4. Sauvegardez et redémarrez

**Via SSH** (alternatif) :

```bash
ssh root@192.168.11.1

# Configuration des paramètres (OBLIGATOIRE)
fwenv_set -8 gpon_sn SMBSXXXXXXXX
fwenv_set -8 equipment_id SagemcomFast5694OFR
fwenv_set -8 hw_ver SMBSXLB7400
fwenv_set -8 cp_hw_ver_sync 1
fwenv_set -8 sw_verA SAHEOFR010117
fwenv_set -8 sw_verB SAHEOFR919117
fwenv_set -8 fix_vlans 0

# Vérification
fw_printenv | grep ^8311

# Redémarrage
reboot
```

### Vérification de la synchronisation

Après redémarrage, connectez la fibre au WAS-110 et vérifiez l'état PLOAM :
- L'état doit être **O5.1** (Associated state)
- Si vous êtes en O2.x ou O3.x, vérifiez le numéro de série

---

## Extraction des identifiants Orange

### Depuis la Livebox (GPON)

1. Connectez-vous sur http://192.168.1.1
2. Allez dans **Informations système** → **ONT**
3. Notez :
   - **Serial Number** : `SMBS12345678` ou `ABCD12345678`
   - **Vendor ID** : `SMBS` ou autre (4 lettres)
   - **MAC Address** de la Livebox (étiquette sous la box)

### Identifiants de connexion Internet

Vous aurez besoin de :
- **Identifiant FTI** : `fti/xxxxxxxx` (visible dans votre espace client Orange)
- **Mot de passe FTI** : celui associé à votre connexion

---

## Génération des options DHCP

### Conformité protocolaire Orange (2023+)

Depuis fin 2022, Orange a durci les contrôles sur les options DHCP :
- Le mot de passe dans l'option 90 (DHCPv4) et 11 (DHCPv6) est vérifié
- La cohérence entre DHCPv4 et DHCPv6 est contrôlée
- Un non-respect entraîne un "parcage" en IP `172.19.x.y`

### Générer l'option 90/11 conforme

Utilisez le générateur de **@kgersen** : https://jsfiddle.net/kgersen/3mnsc6wy/

1. Entrez votre identifiant FTI (ex: `fti/xxxxxxxx`)
2. Entrez votre mot de passe FTI
3. Le champ **SALT** peut être laissé par défaut ou modifié (challenge CHAP)
4. Copiez la chaîne hexadécimale générée (140 caractères)

**Format de l'option :**
```
0x00000558010341010dXXXX... (140 caractères hexa)
```

⚠️ **L'option 90 (DHCPv4) et l'option 11 (DHCPv6) doivent être identiques.**

### Options DHCP complètes

**DHCPv4 :**

| Option | Code | Valeur hexadécimale |
|--------|------|---------------------|
| Vendor Class Identifier | 60 | `0x736167656d` ("sagem") |
| User Class | 77 | `0x2b46535644534c5f6c697665626f782e496e7465726e65742e736f66746174686f6d652e4c697665626f7833` |
| Authentication | 90 | `0x[valeur générée - 140 caractères]` |
| Client ID | 61 | MAC Address de la Livebox |

**DHCPv6 :**

| Option | Code | Valeur hexadécimale |
|--------|------|---------------------|
| Vendor Class | 16 | `0x0000040e0005736167656d` |
| User Class | 15 | `0x002b46535644534c5f6c697665626f782e496e7465726e65742e736f66746174686f6d652e6c697665626f78340a` |
| Authentication | 11 | `0x[même valeur que option 90]` |

---

## Configuration du routeur - IPv4

### Configuration Mikrotik RouterOS

**1. Définition des interfaces**

```routeros
/interface ethernet
set [ find default-name=sfp-sfpplus10 ] name=ether10-WAN comment="WAN-ONU"
set [ find default-name=sfp-sfpplus12 ] name=ether12-LAN comment="LAN"
```

**2. Création du bridge WAN avec MAC spoofing**

```routeros
# Remplacez XX:XX:XX:XX:XX:XX par l'adresse MAC de votre Livebox
/interface bridge
add name=br-wan admin-mac=XX:XX:XX:XX:XX:XX auto-mac=no
```

**3. Configuration du VLAN 832 (Internet)**

```routeros
/interface vlan
add comment="Internet ONT" interface=ether10-WAN name=vlan832-internet vlan-id=832
```

**4. Association VLAN au bridge**

```routeros
/interface bridge port
add bridge=br-wan interface=vlan832-internet
```

**5. Filtre COS=6 pour DHCP**

La priorité COS=6 est **obligatoire** pour que le BNG Orange accepte les requêtes DHCP :

```routeros
/interface bridge filter
add action=set-priority chain=output dst-port=67 ip-protocol=udp \
    mac-protocol=ip new-priority=6 out-interface=vlan832-internet passthrough=yes \
    log=yes log-prefix="Set CoS6 on DHCP request"
```

**6. Options DHCP Client**

```routeros
/ip dhcp-client option
add code=60 name=vendor-class-identifier value=0x736167656d
add code=77 name=userclass value="0x2b46535644534c5f6c697665626f782e496e7465726e65742e736f66746174686f6d652e4c697665626f7833"
add code=90 name=authsend value=0xVOTRE_OPTION_90_GENEREE
```

**7. Lancement du client DHCP**

```routeros
/ip dhcp-client
add dhcp-options=hostname,clientid,authsend,userclass,vendor-class-identifier \
    disabled=no interface=br-wan
```

**8. Configuration du serveur DHCP LAN**

```routeros
/ip address
add address=192.168.1.1/24 interface=ether12-LAN network=192.168.1.0

/ip pool
add name=pool_lan ranges=192.168.1.100-192.168.1.200

/ip dhcp-server
add address-pool=pool_lan disabled=no interface=ether12-LAN name=LAN

/ip dhcp-server network
add address=192.168.1.0/24 dns-server=8.8.8.8,8.8.4.4 gateway=192.168.1.1
```

**9. NAT**

```routeros
/ip firewall nat
add action=masquerade chain=srcnat out-interface=br-wan
```

**10. Activation du FastPath**

```routeros
/ip settings
set allow-fast-path=yes

/ip firewall filter
add chain=forward action=fasttrack-connection connection-state=established,related
add chain=forward action=accept connection-state=established,related
```

---

## Configuration du routeur - IPv6

### Filtre COS=6 pour DHCPv6

```routeros
/interface bridge filter
add chain=output action=set-priority new-priority=6 mac-protocol=ipv6 \
    ip-protocol=udp dst-port=547 out-interface=vlan832-internet
```

### Options DHCPv6

```routeros
/ipv6 dhcp-client option
add code=16 name=class-identifier value=0x0000040e0005736167656d
add code=15 name=userclass value="0x002b46535644534c5f6c697665626f782e496e7465726e65742e736f66746174686f6d652e6c697665626f78340a"
add code=11 name=authsend value=0xVOTRE_OPTION_11_GENEREE
```

⚠️ **L'option 11 doit être identique à l'option 90 du DHCPv4**

### Acceptation des Router Advertisements

```routeros
# ATTENTION : Depuis RouterOS 7.9.1, cette option est sécurisée
/ipv6 settings
set accept-router-advertisements=no
```

### Règle pare-feu pour réponse DHCPv6

```routeros
/ipv6 firewall filter
add chain=input action=accept in-interface=br-wan \
    src-address=fe80::ba0:bab/128 protocol=udp dst-port=546
```

### Client DHCPv6 avec délégation de préfixe

```routeros
/ipv6 dhcp-client
add interface=br-wan dhcp-options=authsend,userclass,class-identifier \
    request=prefix pool-name=pool_FT_6 pool-prefix-length=64 add-default-route=yes
```

### Annonce du préfixe IPv6 sur le LAN

```routeros
/ipv6 address
add address=::1/64 from-pool=pool_FT_6 interface=ether12-LAN advertise=yes
```

### Activation du FastPath IPv6

```routeros
/ipv6 settings
set allow-fast-path=yes

/ipv6 firewall filter
add chain=forward action=fasttrack-connection connection-state=established,related
add chain=forward action=accept connection-state=established,related
```

---

## Configuration du pare-feu

### Listes d'adresses IPv4

```routeros
/ip firewall address-list
# Réseaux autorisés
add address=192.168.1.0/24 list=support
add address=192.168.88.0/24 list=support

# Bogons (adresses invalides depuis le WAN)
add address=0.0.0.0/8 comment="Self-Identification [RFC 3330]" list=bogons
add address=127.0.0.0/16 comment="Loopback [RFC 3330]" list=bogons
add address=169.254.0.0/16 comment="Link Local [RFC 3330]" list=bogons
add address=192.0.2.0/24 comment="Reserved - IANA - TestNet1" list=bogons
add address=198.51.100.0/24 comment="Reserved - IANA - TestNet2" list=bogons
add address=203.0.113.0/24 comment="Reserved - IANA - TestNet3" list=bogons
```

### Règles pare-feu IPv4

```routeros
/ip firewall filter
# Protection contre les attaques SYN flood
add action=add-src-to-address-list address-list=Syn_Flooder \
    address-list-timeout=30m chain=input connection-limit=30,32 protocol=tcp tcp-flags=syn
add action=drop chain=input src-address-list=Syn_Flooder

# Détection de scan de ports
add action=add-src-to-address-list address-list=Port_Scanner \
    address-list-timeout=1w chain=input protocol=tcp psd=21,3s,3,1
add action=drop chain=input src-address-list=Port_Scanner

# Acceptation des connexions établies
add action=accept chain=input connection-state=established,related
add action=accept chain=forward connection-state=established,related

# Drop des bogons
add action=drop chain=forward dst-address-list=bogons

# Blocage accès Winbox depuis l'extérieur
add action=drop chain=input dst-port=8291 protocol=tcp src-address-list=!support

# Protection SSH bruteforce
add action=drop chain=input dst-port=22 protocol=tcp src-address-list=ssh_blacklist
add action=add-src-to-address-list address-list=ssh_blacklist \
    address-list-timeout=1w3d chain=input connection-state=new dst-port=22 \
    protocol=tcp src-address-list=ssh_stage3
add action=add-src-to-address-list address-list=ssh_stage3 \
    address-list-timeout=1m chain=input connection-state=new dst-port=22 \
    protocol=tcp src-address-list=ssh_stage2
add action=add-src-to-address-list address-list=ssh_stage2 \
    address-list-timeout=1m chain=input connection-state=new dst-port=22 \
    protocol=tcp src-address-list=ssh_stage1
add action=add-src-to-address-list address-list=ssh_stage1 \
    address-list-timeout=1m chain=input connection-state=new dst-port=22 protocol=tcp

# Drop final
add action=drop chain=input comment="Drop tout le reste"
```

### Listes d'adresses IPv6

```routeros
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
```

### Règles pare-feu IPv6

```routeros
/ipv6 firewall filter
# Acceptation DHCPv6
add action=accept chain=input dst-port=546 in-interface=br-wan \
    protocol=udp src-address=fe80::ba0:bab/128

# Connexions établies
add action=accept chain=input connection-state=established,related,untracked
add action=drop chain=input connection-state=invalid

# ICMPv6 (nécessaire pour IPv6)
add action=accept chain=input protocol=icmpv6

# Traceroute UDP
add action=accept chain=input port=33434-33534 protocol=udp

# DHCPv6 prefix delegation
add action=accept chain=input dst-port=546 protocol=udp src-address=fe80::/16

# IPsec
add action=accept chain=input dst-port=500,4500 protocol=udp
add action=accept chain=input protocol=ipsec-ah
add action=accept chain=input protocol=ipsec-esp
add action=accept chain=input ipsec-policy=in,ipsec

# Drop du reste (log pour debug)
add action=drop chain=input in-interface-list=!LAN log=yes log-prefix=IPV6-TRASH

# Forward
add action=accept chain=forward connection-state=established,related,untracked
add action=drop chain=forward connection-state=invalid
add action=accept chain=forward protocol=icmpv6
add action=drop chain=forward src-address-list=bad_ipv6
add action=drop chain=forward dst-address-list=bad_ipv6
```

---

## Vérification et dépannage

### Vérifier l'état DHCP

**DHCPv4 :**
```routeros
/ip dhcp-client print detail
```
Le status doit être `bound`.

**DHCPv6 :**
```routeros
/ipv6 dhcp-client print detail
```

### Codes de retour Orange (option 125/17)

| Code | Signification |
|------|---------------|
| 00xx | ✅ OK - Tout fonctionne |
| 01xx | Box/firmware bloqué ou COS incorrecte |
| 0102 | Ligne blacklistée (comportement trop agressif) |
| 0199 | Mauvaise COS sur le DHCP |
| 02xx | ❌ Erreur login/mot de passe/encodage |
| 03xx | Compte ou service résilié |
| 04xx | Problème de facturation |

### IP de parcage

Si vous obtenez une IP en `172.19.x.y` ou `172.16.x.y`, vérifiez :
1. L'option 90/11 (mot de passe)
2. La cohérence DHCPv4/DHCPv6
3. La COS=6 sur les requêtes DHCP

### Tests de connectivité

```bash
# Test IPv4
ping 8.8.8.8

# Test IPv6
ping6 2001:4860:4860::8888

# Test DNS
nslookup google.com
```

### Test de débit

Utilisez https://www.speedtest.net ou :
```bash
speedtest-cli --server-id=XXXX
```

---

## Sources et remerciements

### Sources principales

- **Guide original GPON 2 Gbps** : [lafibre.info - Gnubyte](https://lafibre.info/remplacer-livebox/guide-de-connexion-fibre-directement-sur-un-routeur-voire-meme-en-2gbps/)
- **Durcissement DHCP Orange** : [lafibre.info - levieuxatorange](https://lafibre.info/remplacer-livebox/durcissement-du-controle-de-loption-9011-et-de-la-conformite-protocolaire/)
- **XGS-PON Bypass** : [lafibre.info - Mastah](https://lafibre.info/remplacer-livebox/xgs-pon-remplacement-de-la-livebox-7-10gbe/)
- **Wiki Orange XGS-PON** : [akhamar.github.io](https://akhamar.github.io/orange-xgs-pon/)
- **Documentation 8311** : [pon.wiki](https://pon.wiki/guides/masquerade-as-the-orange-sa-livebox-7-with-the-was-110/)
- **Générateur option 90** : [kgersen - JSFiddle](https://jsfiddle.net/kgersen/3mnsc6wy/)

### Remerciements

- **@Gnubyte** - Auteur du guide original et pionnier du bypass GPON
- **@levieuxatorange** - Expert Orange, documentation conformité protocolaire
- **@Mastah** - Guide XGS-PON
- **@kgersen** - Générateur d'option 90
- **@upnatom** - Hack original de la carte BCM57810s
- **Communauté 8311** - Firmware et documentation WAS-110
- **La communauté lafibre.info** - Tests et retours d'expérience

---

## Licence

Ce tutoriel est basé sur les contributions de la communauté lafibre.info, sous licence [Creative Commons BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

---

*Dernière mise à jour : Décembre 2024*
