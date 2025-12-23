# 🔌 Bypass Livebox Orange - Connexion Fibre Directe

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

> Guide complet pour se connecter à la fibre Orange sans Livebox, jusqu'à 8 Gbps symétrique en XGS-PON.

## ⚠️ Avertissement

**Ce projet est destiné aux utilisateurs avancés** ayant les compétences techniques nécessaires. La manipulation implique :
- Remplacement du matériel Orange fourni par du matériel tiers
- Configuration réseau avancée (VLAN, DHCP, IPv6)
- Perte du support technique Orange

**Prérequis matériels obligatoires :**
- Réseau local 10 Gbps minimum
- Routeur compatible (Mikrotik CCR2004 recommandé)
- ONU compatible (WAS-110 pour XGS-PON, FS.COM pour GPON)

## 📚 Documentation

| Fichier | Description |
|---------|-------------|
| [tutoriel-bypass-livebox-orange.md](tutoriel-bypass-livebox-orange.md) | **Tutoriel complet** avec explications détaillées |
| [config-mikrotik-ipv4.rsc](config-mikrotik-ipv4.rsc) | Configuration IPv4 pour Mikrotik RouterOS |
| [config-mikrotik-ipv6.rsc](config-mikrotik-ipv6.rsc) | Configuration IPv6 pour Mikrotik RouterOS |
| [config-mikrotik-firewall.rsc](config-mikrotik-firewall.rsc) | Règles pare-feu IPv4 et IPv6 |

## 🚀 Quick Start

### 1. Vérifier votre éligibilité

| Votre offre | Technologie | ONU recommandé |
|-------------|-------------|----------------|
| Livebox Up (2 Gbps) | GPON | FS.COM GPON-ONU-34-20BI |
| Livebox Max (5+ Gbps) | XGS-PON | WAS-110 avec firmware 8311 |

### 2. Récupérer vos identifiants

1. **Numéro de série ONT** : Interface Livebox → Informations système → ONT
2. **MAC Address Livebox** : Étiquette sous la Livebox
3. **Identifiant FTI** : Espace client Orange
4. **Mot de passe FTI** : Fourni à l'activation

### 3. Générer l'option DHCP

Utilisez le générateur : https://jsfiddle.net/kgersen/3mnsc6wy/

### 4. Configurer l'ONU

**Pour WAS-110 (XGS-PON) :**
```
PON Serial Number : SMBSXXXXXXXX
Hardware Version  : SMBSXLB7400
Fix VLANs        : Désactivé
```

### 5. Configurer le routeur

Adaptez et exécutez les fichiers `.rsc` dans votre routeur Mikrotik.

## 📊 Performances attendues

| Offre | Download | Upload |
|-------|----------|--------|
| Orange 2 Gbps | ~2.3 Gbps | ~800 Mbps |
| Orange 5 Gbps | ~5 Gbps | ~1 Gbps |
| Orange Pro 8 Gbps | ~8 Gbps | ~8 Gbps |

## 🛠️ Dépannage

| Symptôme | Cause probable | Solution |
|----------|----------------|----------|
| ONU reste en O2/O3 | Numéro de série incorrect | Vérifier le SN de la Livebox |
| IP en 172.19.x.x | Option 90 invalide | Régénérer avec mot de passe |
| Pas d'IPv6 | Option 11 différente | Synchroniser avec option 90 |
| Débit bridé | COS≠6 sur DHCP | Vérifier les filtres bridge |

## 📖 Sources

Ce projet est basé sur le travail de la communauté [lafibre.info](https://lafibre.info/remplacer-livebox/) :

- [@Gnubyte](https://lafibre.info/profile/?u=9225) - Guide original GPON 2 Gbps
- [@levieuxatorange](https://lafibre.info/profile/?u=55234) - Documentation DHCP Orange
- [@Mastah](https://lafibre.info/profile/?u=4535) - Guide XGS-PON
- [@kgersen](https://lafibre.info/profile/?u=4325) - Générateur option 90
- [Communauté 8311](https://pon.wiki) - Firmware WAS-110

## 📄 Licence

Ce projet est sous licence [Creative Commons BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

Vous êtes libre de :
- **Partager** — copier et redistribuer le matériel
- **Adapter** — transformer et créer à partir du matériel

Sous les conditions suivantes :
- **Attribution** — Vous devez créditer les auteurs
- **Partage dans les mêmes conditions** — Même licence pour les dérivés

---

*Dernière mise à jour : Décembre 2024*
