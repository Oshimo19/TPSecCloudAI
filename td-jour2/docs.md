# **Jour 2 - TD : Sécurité appliquée au Cloud**
## **Filtrage réseau et détection d'intrusion sur AWS, avec Terraform**

---

## 1. Prérequis et poste de travail

Terraform pilote AWS à votre place : il faut donc lui donner de quoi s'authentifier, et préparer quelques valeurs réutilisées tout au long du TD.

---

### 1.1 Vérifier Terraform

```bash
terraform -version
```

**Sortie attendue** :

```
Terraform v1.15.2
on linux_amd64
```

> Si la commande échoue ou si la version est trop ancienne, suivre la documentation officielle : https://developer.hashicorp.com/terraform/install

---

### 1.2 Configurer l'accès AWS

Créer le fichier de credentials AWS et ajoutez les identifiants fournis par le formateur :

```bash
mkdir -p ~/.aws
vim ~/.aws/credentials
```

```ini
[default]
aws_access_key_id     = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
region                = eu-west-3
```

Vérifier ensuite que la configuration est opérationnelle :

```bash
aws sts get-caller-identity --region eu-west-3
```

**Sortie attendue** :

```json
{
    "UserId": "AIDAXXXXXXXXXXXXX",
    "Account": "747AXXXXXXXX",
    "Arn": "arn:aws:iam::747AXXXXXXXX:user/votrelogin"
}
```

> Si l'identité IAM s'affiche, l'accès AWS est correctement configuré.

---

### 1.3 Récupérer l'IP publique

Cette IP sera utilisée pour restreindre l'accès SSH au bastion à votre seule machine.

```bash
curl https://checkip.amazonaws.com
```

**Exemple de sortie** :

```
78.203.39.33
```

> Noter cette valeur sous la forme **`78.203.39.33/32`** — on en aura besoin dans les variables Terraform.

---

### 1.4 Générer les paires de clés SSH

Bonne pratique : **Une paire de clés par serveur**, pour limiter l'impact d'une compromission.

| Clé | Serveur cible |
|-----|--------------|
| `td-j2-key-bastion` | Instance bastion (publique) |
| `td-j2-key-private` | Instance privée |
| `td-j2-key-sonde` | Instance Suricata |

**Génération** — algorithme ED25519 recommandé pour sa sécurité et sa compacité :

```bash
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/td-j2-key-bastion -C "td-j2-bastion"
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/td-j2-key-private -C "td-j2-private"
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/td-j2-key-sonde   -C "td-j2-sonde"
```

> L'option `-a 100` augmente le nombre d'itérations de dérivation de la passphrase, rendant une attaque brute-force significativement plus coûteuse.

**Restreindre les permissions** (obligatoire — SSH refusera sinon) :

```bash
chmod 400 ~/.ssh/td-j2-key-bastion
chmod 400 ~/.ssh/td-j2-key-private
chmod 400 ~/.ssh/td-j2-key-sonde
```

**Vérifier les clés publiques générées** :

```bash
cat ~/.ssh/td-j2-key-bastion.pub
cat ~/.ssh/td-j2-key-private.pub
cat ~/.ssh/td-j2-key-sonde.pub
```

**Exemple de sortie** :

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... td-j2-bastion
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... td-j2-private
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... td-j2-sonde
```

> Ces clés publiques seront importées dans AWS via Terraform à l'étape suivante.

---

### 1.5 Créer la structure de travail

```bash
mkdir -p td-jour2/td2-terraform
cd td2-terraform
```

**Structure attendue** :

```
td-jour2/
├── td2-terraform/
└── docs.md
```

> Si on utilise Git, ajouter immédiatement `terraform.tfvars` et `*.tfstate*` au `.gitignore` pour ne jamais exposer les secrets ni l'état de l'infrastructure.

```bash
cat <<'EOF' > .gitignore
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
EOF
```

---

# 2. Le socle Terraform : provider et VPC par défaut

---

## 2.1 Fichiers de configuration

Les fichiers `provider.tf`, `variables.tf`, `data.tf` et `terraform.tfvars` ont été mis en place. Pour rappel, la structure actuelle :

```
td2-terraform/
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── data.tf
└── keys.tf
```

---

## 2.2 Initialisation du provider

```bash
terraform init
```

**Sortie obtenue** :

```
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

> Terraform a téléchargé le plugin AWS et créé le fichier `.terraform.lock.hcl` qui **fixe la version exacte** du provider. Ce fichier doit être commité (contrairement à `terraform.tfstate`).

---

## 2.3 Prévisualisation

```bash
terraform plan
```

**Sortie obtenue** :

```
data.aws_ami.al2023: Reading...
data.aws_vpc.default: Reading...
data.aws_ami.al2023: Read complete after 0s [id=ami-05dfcc4b49790367c]
data.aws_vpc.default: Read complete after 1s [id=vpc-0ebcdb39f7a526ef9]
data.aws_subnet.public_a: Reading...

Plan: 3 to add, 0 to change, 0 to destroy.

│ Error: no matching EC2 Subnet found
│   with data.aws_subnet.public_a,
│   on data.tf line 7
```

**Le plan lui-même est correct** — les 3 paires de clés seraient bien créées. L'erreur vient uniquement du filtre `default_for_az = true` sur le subnet : AWS ne trouve pas de subnet marqué comme défaut en `eu-west-3a` dans ce compte.

**Correction dans `data.tf`** — on retire le filtre restrictif et on laisse Terraform trouver le subnet par VPC + AZ uniquement :

```hcl
data "aws_subnet" "public_a" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "eu-west-3a"
  # default_for_az    = true -> retire : pas de subnet par defaut dans ce compte
}
```

Relancez :

```bash
terraform plan
```

**Sortie attendue** :

```
data.aws_vpc.default: Reading...
data.aws_ami.al2023: Reading...
data.aws_ami.al2023: Read complete after 1s [id=ami-05dfcc4b49790367c]
data.aws_vpc.default: Read complete after 1s [id=vpc-0ebcdb39f7a526ef9]
data.aws_subnet.public_a: Reading...
data.aws_subnet.public_a: Read complete after 1s [id=subnet-095c2c562da7511cc]

Plan: 3 to add, 0 to change, 0 to destroy.
```

> `0 to add` sur les data sources : normal, elles **lisent** des ressources existantes sans rien créer. Les 3 paires de clés sont prêtes à être créées au prochain `apply`.

---

## Questions — Partie 1

**Q1 — Quelle est la différence entre une `resource` et une `data source` ? Pourquoi le VPC par défaut est-il déclaré en `data source` ?**

Une **resource** est un objet dont Terraform gère le cycle de vie complet : il le crée, le modifie si la configuration change, et le supprime avec `destroy`. Une **data source** est en lecture seule : Terraform lit ses attributs pour les réutiliser ailleurs, mais ne le gère jamais.

Le VPC par défaut est déclaré en data source car **il existe déjà** dans le compte AWS — Terraform n'a pas à le créer. Surtout, le déclarer en `resource` serait dangereux : un `terraform destroy` le supprimerait, cassant toute l'infrastructure du compte.

**Q2 — À quoi sert le fichier `terraform.tfstate` ?**

C'est la **mémoire de Terraform**. Il y enregistre l'état réel de chaque ressource gérée (IDs AWS, attributs, dépendances). C'est grâce à lui que :
* `plan` calcule la **différence** entre l'état actuel et la configuration déclarée
* `destroy` sait exactement **quoi supprimer** — et rien d'autre

Par défaut il est stocké localement (`terraform.tfstate`). La documentation Terraform recommande de le stocker dans **HCP Terraform ou un backend distant** (S3, etc.) pour deux raisons : collaborer en équipe, et éviter de perdre l'état si le fichier local est supprimé. Il ne faut **jamais le commiter** dans Git car il peut contenir des secrets en clair.

---



---
