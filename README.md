# TDs — Sécuriser une architecture AWS

> VPC · EC2 · Security Groups · NACL · Terraform · Ansible

**[Documentation pour TD Jour 1](./td-jour1/docs.md)**

---

## Structure du TD Jour 1

```
td-jour1/
├── Makefile
├── main.sh
├── docs.md
├── app/
│   └── services/
│       ├── ec2.sh        # Scripts AWS EC2
│       ├── iam.sh        # Scripts AWS IAM
│       ├── main.sh       # Point d'entrée app (NACL lifecycle)
│       └── vpc.sh        # Scripts AWS VPC
└── infra/
    ├── ansible/
    │   ├── ansible.cfg
    │   ├── inventory.ini
    │   └── ngnix.yml     # Playbook installation nginx
    ├── cli/
    │   ├── constants/
    │   │   └── vpc.sh    # VPC_ID partagé
    │   └── services/
    │       └── ec2.sh    # Fonctions NACL (create/delete/rules)
    └── terraform/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── provider.tf
        └── terraform.tfvars
```

---

## Prérequis pour TD Jour 1

- AWS CLI configuré (`~/.aws/credentials`)
- Terraform >= 1.0
- Ansible >= 2.9
- Clés SSH ED25519 générées

---

## Utilisation rapide de TD Jour 1

```bash
# Déployer l'infra
cd infra/terraform && terraform init && terraform apply

# Provisionner nginx via Ansible
cd infra/ansible && ansible-playbook -i inventory.ini ngnix.yml

# Tester le cycle de vie NACL via script
bash app/services/main.sh <nom-nacl>

# Détruire
cd infra/terraform && terraform destroy
```

> Ne pas commiter `terraform.tfvars` ni `~/.aws/credentials`
