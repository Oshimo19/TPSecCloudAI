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

```bash
curl https://checkip.amazonaws.com
```

Exemple de sortie :

```
78.203.39.33
```

> Noter cette valeur sous la forme **`78.203.39.33/32`** — on en aura besoin dans les variables Terraform.

---

### 1.4 Générer les paires de clés SSH

Bonne pratique : **une paire de clés par serveur**, pour limiter l'impact d'une compromission.

| Clé | Serveur cible |
|-----|---------------|
| `td-j2-key-bastion` | Instance bastion (publique) |
| `td-j2-key-private` | Instance privée |
| `td-j2-key-sonde` | Instance Suricata |

```bash
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/td-j2-key-bastion -C "td-j2-bastion"
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/td-j2-key-private -C "td-j2-private"
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/td-j2-key-sonde   -C "td-j2-sonde"
```

> L'option `-a 100` augmente le nombre d'itérations de dérivation de la passphrase, rendant une attaque brute-force significativement plus coûteuse.

```bash
chmod 400 ~/.ssh/td-j2-key-bastion
chmod 400 ~/.ssh/td-j2-key-private
chmod 400 ~/.ssh/td-j2-key-sonde
```

```bash
cat ~/.ssh/td-j2-key-bastion.pub
cat ~/.ssh/td-j2-key-private.pub
cat ~/.ssh/td-j2-key-sonde.pub
```

Exemple de sortie :

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
cd td-jour2/td2-terraform
```

Structure attendue :

```
td-jour2/
├── td2-terraform/
└── docs.md
```

> Si on utilise Git, ajouter immédiatement `terraform.tfvars` et `*.tfstate*` au `.gitignore`.

```bash
cat <<'EOF' > .gitignore
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
EOF
```

---

## 2. Le socle Terraform : provider et VPC par défaut

### 2.1 Fichiers de configuration

Les fichiers `provider.tf`, `variables.tf`, `data.tf`, `terraform.tfvars`, `keys.tf` et `network.tf` ont été mis en place. Structure actuelle :

```
td2-terraform/
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── data.tf
├── keys.tf
└── network.tf
```

### 2.2 Initialisation du provider

```bash
terraform init
```

Sortie obtenue :

```
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

> Terraform a téléchargé le plugin AWS et créé le fichier `.terraform.lock.hcl` qui **fixe la version exacte** du provider. Ce fichier doit être commité (contrairement à `terraform.tfstate`).

---

### 2.3 Création du sous-réseau et prévisualisation

Plutôt que de réutiliser un subnet existant partagé avec d'autres étudiants, on crée le nôtre dans le VPC par défaut. Cela évite les conflits et garantit la maîtrise du CIDR.

**`data.tf`** — on retire le bloc `data "aws_subnet"` (on ne lit plus un subnet existant) :

```hcl
data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

locals {
  prefix = "td2-${var.student_id}"
}
```

**`variables.tf`** — ajouter la variable de description des subnets :

```hcl
variable "subnets_cidr_block" {
  description = "Map des subnets a creer"
  type = map(object({
    cidr   = string
    az     = string
    public = bool
  }))
  default = {
    "public-a" = {
      cidr   = "172.31.55.0/24"
      az     = "eu-west-3a"
      public = true
    }
  }
}
```

**`network.tf`** — nouveau fichier, création du subnet avec `for_each` :

```hcl
resource "aws_subnet" "td2_subnets" {
  for_each                = var.subnets_cidr_block
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public

  tags = {
    Name = "${local.prefix}-subnet-${each.key}"
  }
}
```

> L'utilisation de `for_each` sur une map permet d'ajouter facilement d'autres subnets (privés, autres AZ) en modifiant uniquement la variable, sans toucher au code de la ressource.

Vérifier que le CIDR `172.31.55.0/24` est libre avant d'appliquer :

```bash
aws ec2 describe-subnets \
  --filters "Name=cidrBlock,Values=172.31.55.0/24" \
  --query "Subnets[*].SubnetId" --output text
```

> Si la commande ne retourne rien, le CIDR est disponible.

Lancer la prévisualisation :

```bash
terraform plan
```

Sortie attendue :

```
data.aws_ami.al2023: Reading...
data.aws_vpc.default: Reading...
data.aws_ami.al2023: Read complete after 1s [id=ami-05dfcc4b49790367c]
data.aws_vpc.default: Read complete after 1s [id=vpc-0ebcdb39f7a526ef9]

Terraform used the selected providers to generate the following execution plan.

  + resource "aws_subnet" "td2_subnets" ["public-a"] {
      + cidr_block              = "172.31.55.0/24"
      + availability_zone       = "eu-west-3a"
      + map_public_ip_on_launch = true
      + tags                    = { "Name" = "td2-<student_id>-subnet-public-a" }
    }
  + resource "aws_key_pair" "bastion" { ... }
  + resource "aws_key_pair" "private" { ... }
  + resource "aws_key_pair" "sonde"   { ... }

Plan: 4 to add, 0 to change, 0 to destroy.
```

> 4 ressources à créer : 1 subnet + 3 paires de clés. Les data sources (VPC, AMI) ne créent rien, elles lisent l'existant.

---

## Questions — Partie 1

**Q1 — Quelle est la différence entre une `resource` et une `data source` ? Pourquoi le VPC par défaut est-il déclaré en `data source` ?**

Une **resource** est un objet dont Terraform gère le cycle de vie complet : il le crée, le modifie si la configuration change, et le supprime avec `destroy`. Une **data source** est en lecture seule : Terraform lit ses attributs pour les réutiliser ailleurs, mais ne le gère jamais.

Le VPC par défaut est déclaré en data source car **il existe déjà** dans le compte AWS — Terraform n'a pas à le créer. Surtout, le déclarer en `resource` serait dangereux : un `terraform destroy` le supprimerait, cassant toute l'infrastructure du compte.

**Q2 — À quoi sert le fichier `terraform.tfstate` ?**

C'est la **mémoire de Terraform**. Il y enregistre l'état réel de chaque ressource gérée (IDs AWS, attributs, dépendances). C'est grâce à lui que :
* `plan` calcule la **différence** entre l'état actuel et la configuration déclarée
* `destroy` sait exactement **quoi supprimer** — et rien d'autre

Par défaut il est stocké localement. Il ne faut **jamais le commiter** dans Git car il peut contenir des secrets en clair. En équipe, on le stocke dans un backend distant (S3 + DynamoDB pour le locking, ou HCP Terraform).

---

## 3. Déploiement du bastion

### 3.1 Fichiers ajoutés

Ajouter `bastion.tf` et `outputs.tf` à la structure. Structure complète :

```
td2-terraform/
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── data.tf
├── keys.tf
├── network.tf
├── bastion.tf
└── outputs.tf
```

**`bastion.tf`** — security group et instance EC2 dans notre subnet, référence le subnet créé via `for_each` et exposer l'IP publique du bastion :

Plus d'info dans [./td2-terraform/bastion.tf](./td2-terraform/bastion.tf)

> Le security group est créé **avant** l'instance et référencé par son ID dans `vpc_security_group_ids`. La dépendance implicite est automatiquement résolue par Terraform.

### 3.2 Déploiement

```bash
terraform apply
```

> Taper `yes` pour confirmer.

Sortie obtenue :

```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

bastion_ip = "51.44.163.74"
```

> 6 ressources créées : 1 subnet + 3 paires de clés + 1 security group + 1 instance bastion.

---

### 3.3 Connexion SSH au bastion

Récupérer l'IP et se connecter :

```bash
cd td2-terraform
ssh -i ~/.ssh/td-j2-key-bastion ec2-user@$(terraform output -raw bastion_ip)
```

> **La commande `terraform output` doit être exécutée depuis le dossier `td2-terraform/`** où se trouve le fichier `terraform.tfstate`. Si elle est lancée depuis un dossier parent, Terraform ne trouve pas d'état et retourne une erreur `No address associated with hostname`. Vérifier toujours le répertoire courant avec `pwd` avant d'exécuter `terraform output`.

On peut aussi passer l'IP directement :

```bash
ssh -i ~/.ssh/td-j2-key-bastion ec2-user@51.44.163.74
```

Sortie obtenue :

```
The authenticity of host '51.44.163.74 (51.44.163.74)' can't be established.
ED25519 key fingerprint is SHA256:ShCFc+igomIW8S11otbMiWUZy2JWHS2aSLuCKAPrFJE.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '51.44.163.74' (ED25519) to the known hosts.
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'
[ec2-user@ip-172-31-55-233 ~]$
```

> La connexion est établie. L'IP interne `172.31.55-233` confirme que l'instance est bien dans notre subnet `172.31.55.0/24`.

```bash
exit
```

---

## Questions — Partie 2

**Q1 — Pourquoi Terraform crée le SG avant l'instance sans qu'on le précise ?**

Parce que dans `bastion.tf`, l'instance référence le SG :

```hcl
vpc_security_group_ids = [aws_security_group.bastion_sg.id]
```

Terraform analyse ce graphe de dépendances et **déduit automatiquement** que `aws_security_group.bastion_sg` doit exister avant `aws_instance.bastion`. Pas besoin de `depends_on` explicite — la référence suffit.

> `depends_on` n'est utile que quand la dépendance est **implicite** (non exprimée par une référence directe).

**Q2 — Remplacer `[var.my_ip]` par `["0.0.0.0/0"]` ?**

Le port 22 (SSH) serait **ouvert au monde entier**. Conséquences concrètes :

| Risque | Détail |
|--------|--------|
| **Brute-force** | Des bots scannent en permanence le port 22 sur toutes les IPs publiques AWS |
| **Exploitation 0-day** | Si une vulnérabilité SSH est découverte, le bastion est exposé immédiatement |
| **Credential stuffing** | Tentatives avec des listes de mots de passe connus |

En pratique, en quelques **minutes** après l'apply, les logs SSH montreraient des centaines de tentatives de connexion.

La bonne pratique : restreindre au `/32` de votre IP, ou passer par **AWS Systems Manager Session Manager** pour ne plus exposer le port 22 du tout.

---

## Section 4 — Filtrage sortant : sous-réseau privé et NAT Gateway

**Objectif** : créer une instance privée sans IP publique, capable de sortir vers Internet via une NAT Gateway — sans être joignable depuis l'extérieur.

---

### 4.1 Fichier `egress.tf`

Plus d'info dans [./td2-terraform/egress.tf](./td2-terraform/egress.tf)

---

### 4.2 Déploiement

```bash
cd td2-terraform
terraform apply
```

**Sortie attendue :**
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:
bastion_ip = "51.44.163.74"
private_ip = "172.31.142.13"
```

---

### 4.3 Connexion et test

**Étape 1 — Activer le SSH agent forwarding (sur votre machine locale) :**

```bash
eval $(ssh-agent)
ssh-add ~/.ssh/td-j2-key-bastion
ssh-add ~/.ssh/td-j2-key-private
```

> L'agent forwarding permet de rebondir sur l'instance privée **sans copier la clé privée sur le bastion** — bonne pratique de sécurité.

**Étape 2 — Connexion au bastion avec forwarding :**

```bash
cd td2-terraform
ssh -A ec2-user@$(terraform output -raw bastion_ip)
```

**Étape 3 — Depuis le bastion, rebondir vers l'instance privée :**

```bash
ssh ec2-user@172.31.142.13
```

**Étape 4 — Depuis l'instance privée, vérifier la sortie Internet :**

```bash
curl -s https://checkip.amazonaws.com
```

**Résultat obtenu :**
```
15.188.247.119   ← IP publique de la NAT Gateway, pas de l'instance
```

---

### 4.4 Ce qui se passe en coulisses

```
instance privée (172.31.142.13)
    │  pas d'IP publique, pas de route directe
    ▼
route table privée → 0.0.0.0/0 → NAT Gateway
    │  SNAT : remplace 172.31.142.13 par 15.188.247.119
    ▼
Internet Gateway → Internet
    │
    ▼
checkip.amazonaws.com répond à 15.188.247.119
    │  NAT retransmet à l'instance privée
    ▼
instance privée reçoit la réponse
```

L'instance privée **sort** vers Internet mais reste **injoignable depuis l'extérieur** — aucune connexion entrante ne peut être initiée vers elle.

---

### Questions — Partie 4

**Q1 — Quelle adresse renvoie `curl checkip` depuis l'instance privée, et pourquoi ?**

L'adresse retournée est **`15.188.247.119`** — l'IP publique de la NAT Gateway. L'instance privée n'a pas d'IP publique (`172.31.142.13` est non routable). La NAT Gateway effectue un **SNAT** : elle substitue l'IP source privée par son IP élastique publique avant d'envoyer le paquet vers l'Internet Gateway. L'instance reste invisible depuis Internet.

---

**Q2 — Pourquoi la NAT Gateway doit-elle être dans le sous-réseau public ?**

La NAT Gateway a besoin d'un accès à l'**Internet Gateway**, qui n'est accessible que depuis un subnet public (table de routage avec `0.0.0.0/0 → igw-xxx`). Placée dans le subnet privé, elle serait dans la même impasse que l'instance privée — sans route vers Internet. Elle sert de **pont** entre les deux mondes :

```
subnet privé → NAT Gateway (subnet public) → Internet Gateway → Internet
```

---

## Section 5 — Sonde Suricata

**Objectif** : déployer une instance Ubuntu avec Suricata en IDS, vérifier la détection de trafic ICMP.

---

### 5.1 Déploiement

```bash
cd ~/secCloudArchInter/TPSecCloudAI/td-jour2/td2-terraform
terraform apply
```

**Sortie attendue :**
```
Apply complete! Resources: X added, 0 changed, 0 destroyed.

Outputs:
bastion_ip    = "51.44.163.74"
private_ip    = "172.31.142.13"
sonde_private_ip = "172.31.55.31"
```

> Attendre **~3 minutes** après l'apply pour laisser le `user_data` terminer l'installation de Suricata.

---

### 5.2 Vérifier l'installation

**Vérifier que Suricata tourne :**

```bash
ssh -i ~/.ssh/td-j2-key-bastion \
  -o ProxyJump="ec2-user@$(terraform output -raw bastion_ip)" \
  ubuntu@$(terraform output -raw sonde_private_ip) \
  "sudo systemctl status suricata --no-pager"
```

**Vérifier que la règle TD2 est bien chargée :**

```bash
ssh -i ~/.ssh/td-j2-key-bastion \
  -o ProxyJump="ec2-user@$(terraform output -raw bastion_ip)" \
  ubuntu@$(terraform output -raw sonde_private_ip) \
  "grep 'TD2' /var/lib/suricata/rules/suricata.rules"
```

**Sortie attendue :**
```
alert icmp any any -> $HOME_NET any (msg:"TD2 ICMP detecte"; sid:1000001; rev:1;)
```

**Vérifier l'interface réseau écoutée :**

```bash
ssh -i ~/.ssh/td-j2-key-bastion \
  -o ProxyJump="ec2-user@$(terraform output -raw bastion_ip)" \
  ubuntu@$(terraform output -raw sonde_private_ip) \
  "grep 'interface' /etc/suricata/suricata.yaml | grep -v '#' | head -5"
```

---

### 5.3 Générer du trafic et observer les alertes

**Terminal 1 — Écouter les alertes en temps réel sur la sonde :**

```bash
ssh -i ~/.ssh/td-j2-key-bastion \
  -o ProxyJump="ec2-user@$(terraform output -raw bastion_ip)" \
  ubuntu@$(terraform output -raw sonde_private_ip) \
  "sudo tail -f /var/log/suricata/eve.json | grep TD2"
```

**Terminal 2 — Générer du trafic ICMP depuis le bastion vers la sonde :**

```bash
ssh -i ~/.ssh/td-j2-key-bastion ec2-user@$(terraform output -raw bastion_ip) \
  "ping -c 5 $(terraform output -raw sonde_private_ip)"
```

**Sortie attendue dans le Terminal 1 :**
```json
{"timestamp":"2026-06-17T15:XX:XX...","event_type":"alert","src_ip":"172.31.55.233",
"dest_ip":"172.31.55.31","proto":"ICMP","alert":{"msg":"TD2 ICMP detecte","sid":1000001}}
```

> Chaque ping génère une alerte. L'IP source (`172.31.55.233`) est celle du bastion, la destination (`172.31.55.31`) est la sonde.

---

### Questions — Partie 5

**Q1 — Quel est l'intérêt de passer l'installation de Suricata en `user_data` plutôt que de l'installer à la main ?**

Le `user_data` est exécuté **automatiquement au premier démarrage** de l'instance. Avantages :

| Manuel | user_data |
|--------|-----------|
| Non reproductible | Reproductible à chaque `terraform apply` |
| Erreurs humaines possibles | Versionné dans Git |
| Ne passe pas à l'échelle | Déployable sur N instances identiques |

C'est le principe d'**infrastructure immuable** : on ne modifie pas une instance en production, on en recrée une nouvelle avec la config correcte.

---

**Q2 — Suricata ici détecte ou bloque-t-il le ping ? Quelle serait la différence avec un IPS ?**

En mode `--af-packet` (mode par défaut), Suricata fonctionne en **IDS** — il **détecte uniquement** :

```
Trafic → interface → Suricata (copie) → alerte dans eve.json
                  ↘ paquet transmis normalement (non bloqué)
```

En mode **IPS** (avec `--af-packet` en mode `IPS` ou via `nfqueue`), Suricata s'intercale dans le chemin du trafic et peut **dropper** les paquets correspondant à une règle `drop` :

```
Trafic → Suricata → DROP (paquet détruit) ou PASS (transmis)
```

Pour passer en IPS sur AWS, il faudrait configurer la sonde comme **inline** entre deux interfaces réseau, ce qui nécessite une configuration VPC plus complexe (routing via l'instance).

---

## Section 6 — Destruction propre

### 6.1 Lancer la destruction

```bash
cd td2-terraform
terraform destroy
```

Taper `yes` pour confirmer. Terraform liste et supprime dans l'ordre correct : instances, NAT Gateway, EIP, sous-réseau, route table, security groups.

**Sortie attendue :**
```
Destroy complete! Resources: X destroyed.
```

> Le VPC par défaut, ses subnets par défaut et son Internet Gateway ne sont pas touchés — ce sont des `data sources`, ils n'apparaissent pas dans le state.

---

### Questions — Partie 6

**Q1 — Pourquoi l'usage d'une `data source` pour le VPC par défaut garantit qu'on ne le supprimera jamais ?**

Terraform ne gère le cycle de vie **que des ressources déclarées avec `resource`**. Une `data source` est en lecture seule : Terraform lit ses attributs mais n'en est pas propriétaire. Elle n'apparaît donc jamais dans le state comme objet à détruire.

Concrètement :

```
terraform destroy → parcourt le state → ne trouve que vos resources
                 → data "aws_vpc" "default" absent du state → intouché
```

Si le VPC était déclaré en `resource`, un `terraform destroy` le supprimerait — cassant toute l'infrastructure du compte AWS partagé.

---
