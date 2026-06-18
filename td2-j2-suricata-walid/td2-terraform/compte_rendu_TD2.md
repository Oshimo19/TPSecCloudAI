# Compte rendu - TD2 Jour 2 : Filtrage réseau et Suricata sur AWS

## 1. Objectif

L'objectif du TD est de déployer une infrastructure AWS avec Terraform pour mettre en pratique le filtrage réseau entrant, le filtrage sortant et la détection d'intrusion avec Suricata.

## 2. Paramètres utilisés

- Région AWS : `eu-west-3` Paris
- VPC utilisé : `vpc-0ebcdb39f7a526ef9`
- Subnet existant utilisé pour le bastion et la NAT : `subnet-095c2c562da7511cc`
- AMI : `ami-0e207c18bb303cc68`
- Type d'instance : `t2.micro`
- IP autorisée pour SSH : `80.214.56.151/32`
- Utilisateur SSH : `ubuntu`
- Clé SSH locale : `/root/.ssh/terraform-ipssi`

## 3. Ressources déployées

Terraform crée :

- un Security Group pour le bastion ;
- un bastion accessible en SSH uniquement depuis mon IP publique ;
- un subnet privé ;
- une Elastic IP et une NAT Gateway ;
- une table de routage privée vers la NAT Gateway ;
- une instance privée ;
- une sonde Suricata dans le subnet privé ;
- les règles de sécurité permettant SSH et ICMP depuis le bastion vers la sonde.

## 4. Filtrage entrant

Le bastion est la seule machine exposée publiquement. Son Security Group autorise uniquement le port TCP/22 depuis mon IP publique en `/32`. Cela évite d'exposer SSH au monde entier.

## 5. Filtrage sortant

Les instances privées n'ont pas d'adresse IP publique. Leur sortie Internet passe par la NAT Gateway placée dans le subnet existant.

## 6. Détection Suricata

La sonde Suricata reçoit une règle locale :

```text
alert icmp any any -> any any (msg:"TD2 ICMP detecte"; sid:1000001; rev:1;)
```

Le test consiste à envoyer un ping depuis le bastion vers la sonde puis à vérifier `/var/log/suricata/fast.log`.

## 7. Commandes exécutées

```bash
make pubkey
make init
make fmt
make validate
make plan
make apply
make inventory
make ping
make ansible
make test-alert
make alerts
```

## 8. Nettoyage

La commande suivante doit être exécutée à la fin :

```bash
make destroy
```

Cette étape est obligatoire car la NAT Gateway est facturée tant qu'elle existe.
