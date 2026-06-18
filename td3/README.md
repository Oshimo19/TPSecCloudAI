# TD3 — Application web 3-tiers sur AWS

Ce dossier contient une solution complète pour le TD Jour 3 : architecture web 3-tiers sur AWS avec Terraform.

Structure :

```text
td3/
├── Makefile
├── .gitignore
├── README.md
└── td-aws/
    ├── providers.tf
    ├── variables.tf
    ├── terraform.tfvars.example
    ├── network.tf
    ├── security.tf
    ├── data.tf
    ├── app_tier.tf
    ├── web_tier.tf
    ├── outputs.tf
    ├── schema.sql
    ├── compte_rendu_TD3.md
    ├── app/
    │   ├── app.py
    │   └── user_data.sh.tpl
    └── web/
        ├── web.py
        └── user_data.sh.tpl
```

## Déploiement rapide

Depuis le dossier `td3` :

```bash
cp td-aws/terraform.tfvars.example td-aws/terraform.tfvars
nano td-aws/terraform.tfvars

make init
make fmt
make validate
make plan
make apply
make outputs
```

Ouvre ensuite l'URL affichée par :

```bash
make site-url
```

## Test fonctionnel

1. Ouvre l'URL de l'ALB public dans ton navigateur.
2. Remplis le formulaire d'inscription.
3. Valide.
4. Tu dois voir un message de succès.
5. Recommence avec le même email : tu dois obtenir une erreur `409` ou un message indiquant que l'email existe déjà.

## Nettoyage obligatoire

RDS, NAT Gateway et ALB sont facturés à l'heure. À la fin :

```bash
make destroy
```

Puis vérifie dans AWS qu'il ne reste pas de NAT Gateway, ALB, RDS ou Elastic IP.

## Version VPC existant
Cette version utilise le VPC existant fourni dans `terraform.tfvars` (`vpc_id`). Elle ne crée pas de nouveau VPC, subnet, NAT Gateway ou Internet Gateway. Elle crée uniquement les ressources applicatives du TD dans ce VPC : Security Groups, ALB public, ALB interne, EC2 web/app, RDS et secret.
