# TD2 J2 Suricata - Ansible

Ce dossier contient les fichiers Ansible pour installer/configurer Suricata et tester une alerte ICMP.

Le fichier `inventory.ini` n'est pas a remplir manuellement. Il est genere automatiquement avec :

```bash
make inventory
```

Puis :

```bash
make ping
make ansible
make test-alert
make alerts
```
