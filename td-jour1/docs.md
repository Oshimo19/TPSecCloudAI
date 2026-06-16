# **Jour 1 - TD : Sécuriser un réseau AWS**
## **VPC par défaut, EC2, Security Groups & NACL**

---

## **1. Mise en place et prérequis**

### **1.1 Configuration de l'environnement AWS CLI**

#### **Objectif**

Configurer la machine locale pour interagir avec AWS en utilisant les identifiants fournis.

#### **Étapes détaillées**

1. **Créer le fichier de configuration AWS** :

```bash
mkdir -p ~/.aws
vim ~/.aws/credentials
```

2. **Ajouter les identifiants AWS** (fournis par le formateur) :

```ini
[default]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
region = eu-west-3
```

**Note** : Assurer que le fichier `~/.aws/credentials` a les permissions suivantes :

```bash
chmod 600 ~/.aws/credentials
```

3. **Vérifier la configuration** :

```bash
aws sts get-caller-identity --region eu-west-3
```

**Exemple de Sortie attendue** :
   
```json
{
    "UserId": "AIDAXXXXXXXXXXXXX",
    "Account": "747AXXXXXXXX",
    "Arn": "arn:aws:iam::747AXXXXXXXX:user/wrm"
}
```

**Validation** : Si cette commande retourne votre identité IAM, la configuration est opérationnelle.

---

### **1.2 Récupération de votre adresse IP publique**

#### **Objectif**

Identifier une adresse IP publique pour configurer les règles de sécurité (Security Groups & NACLs) avec précision.

#### **Commande** :

```bash
curl https://checkip.amazonaws.com
```

#### **Exemple de sortie** :

```
78.203.39.33
```

**Bonnes pratiques** :
* Cette IP sera utilisée sous la forme **`78.203.39.33/32`** dans les règles de sécurité.
* **Ne partagez jamais cette IP publiquement** (ex : dans des commits Git).
* Conservez-la dans un **fichier sécurisé** (ex : `notes.md` chiffré) ou utilisez une **variable d'environnement**.

---

### **1.3 Génération des paires de clés SSH**

#### **Objectif**

Créer des clés SSH pour sécuriser l'accès aux instances EC2 (bastion et serveur web).

#### **Choix techniques** :

* **Algorithme** : ED25519 (recommandé pour sa sécurité et sa performance).
* **Longueur de la clé** : `-a 100` (nombre d'itérations pour renforcer la sécurité).
* **Noms de fichiers** :
  * `td-j1-key-bastion` (pour l'instance bastion).
  * `td-j1-key-web` (pour le serveur web).

#### **Commandes** :

```bash
# Génération de la paire de clés pour le bastion
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/td-j1-key-bastion -C "bastion"

# Génération de la paire de clés pour le serveur web
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/td-j1-key-web -C "web"
```

#### **Permissions recommandées** :

```bash
chmod 400 ~/.ssh/td-j1-key-bastion
chmod 400 ~/.ssh/td-j1-key-web
```

#### **Affichage des clés publiques** :

```bash
cat ~/.ssh/td-j1-key-bastion.pub
cat ~/.ssh/td-j1-key-web.pub
```

**À conserver** : Copier le contenu des clés publiques dans un **fichier de suivi** (ex : `notes.md`) pour les utiliser ultérieurement dans les Security Groups.

---

### **1.4 Préparation du fichier de suivi**

#### **Objectif** :

Centraliser les identifiants et configurations générés pour une traçabilité optimale.

#### **Structure suggérée** :

```markdown
# Suivi - Jour 1 - Sécurisation AWS

## Configuration initiale
- **Région AWS** : eu-west-3 (Paris)
- **AMI utilisée** : ami-0e207c18bb303cc68 (Ubuntu 24.04 LTS AMD64)
- **IP publique** : 78.203.39.33/32

## Clés SSH
- **Bastion** : td-j1-key-bastion (publique : `ssh-ed25519 AAAAC3... bastion`)
- **Web** : td-j1-key-web (publique : `ssh-ed25519 AAAAC3... web`)
```

**Conseil** : Éviter de commiter ce fichier dans un dépôt Git public.

---

# **2. Explorer le VPC par défaut**

Le compte AWS dispose d'un **VPC par défaut** préconfiguré avec :
- Une plage CIDR : `172.31.0.0/16`
- Un sous-réseau par zone de disponibilité (AZ)
- Une **Internet Gateway (IGW)** pour le trafic sortant
- Une table de routage configurée pour acheminer `0.0.0.0/0` vers l'IGW

**Remarque** : Tous les sous-réseaux par défaut sont **publics** (accès Internet direct). Pour un environnement sécurisé, créez un VPC personnalisé avec des sous-réseaux privés/publics.

---

## **2.1. Identifier le VPC par défaut**

### **Objectif** :
Repérer le VPC marqué comme "par défaut" et noter son `vpc-id`.

#### **Commande AWS CLI** :
```bash
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region eu-west-3
```

#### **Exemple de résultat** :
```json
{
    "Vpcs": [
        {
            "VpcId": "vpc-0ebcdb39f7a526ef9",
            "CidrBlock": "172.31.0.0/16",
            "IsDefault": true,
            "State": "available",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "VPC-AnadeArmas"
                }
            ]
        }
    ]
}
```

**Infos extraites** :
* **ID VPC** : `vpc-0ebcdb39f7a526ef9`
* **CIDR** : `172.31.0.0/16`

---

## **2.2. Lister les sous-réseaux par défaut**

### **Objectif** :
Identifier les sous-réseaux associés au VPC par défaut et leurs zones de disponibilité.

#### **Commande AWS CLI** :
```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-0ebcdb39f7a526ef9" \
  --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch]" \
  --output table \
  --region eu-west-3
```

#### **Exemple de résultat** :
```
--------------------------------------------------------------------------------
|                          DescribeSubnets                                     |
+---------------------------+-------------+-------------------+----------------+
|  subnet-0b262aa3958b5b1b6 |  eu-west-3a |  172.31.201.0/24  |  False        |
|  subnet-0f7c776e83e039e9a |  eu-west-3b |  172.31.30.0/24   |  False        |
|  subnet-04dd5c4069a56bade |  eu-west-3a |  172.31.40.0/24   |  True         |
|  subnet-0b20f54725dddb8a9 |  eu-west-3a |  172.31.250.0/24  |  True         |
+---------------------------+-------------+-------------------+----------------+
```

**Sous-réseaux publics identifiés** (ceux avec `MapPublicIpOnLaunch: True`) :
| Zone | ID du sous-réseau | CIDR Block |
|------|-------------------|------------|
| eu-west-3a | `subnet-04dd5c4069a56bade` | `172.31.40.0/24` |
| eu-west-3a | `subnet-0b20f54725dddb8a9` | `172.31.250.0/24` |

---

## **2.3. Vérifier la table de routage**

### **Objectif** :
Confirmer que la table de routage du VPC envoie bien le trafic `0.0.0.0/0` vers l'Internet Gateway (IGW).

#### **Commande AWS CLI** :
```bash
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=vpc-0ebcdb39f7a526ef9" \
  --query "RouteTables[*].Routes[?DestinationCidrBlock=='0.0.0.0/0']" \
  --output json \
  --region eu-west-3
```

#### **Exemple de résultat** :
```json
[
    {
        "DestinationCidrBlock": "0.0.0.0/0",
        "GatewayId": "igw-06d61463409eb8f84",
        "Origin": "CreateRoute",
        "State": "active"
    }
]
```

---

### **Récapitulatif**
| Ressource | ID | CIDR Block | Zone | Type |
|-----------|----|------------|------|------|
| **VPC** | `vpc-0ebcdb39f7a526ef9` | `172.31.0.0/16` | - | Default |
| **Subnet public** | `subnet-04dd5c4069a56bade` | `172.31.40.0/24` | eu-west-3a | Public |
| **Subnet public** | `subnet-0b20f54725dddb8a9` | `172.31.250.0/24` | eu-west-3a | Public |
| **Internet Gateway** | `igw-06d61463409eb8f84` | - | - | - |

---

# **3. Déploiement des instances EC2 via Terraform**

## **3.1 Structure du projet Terraform**

```
td-j1/
├── main.tf          # Ressources principales
├── variables.tf     # Déclaration des variables
├── terraform.tfvars # Valeurs des variables (non commité)
└── outputs.tf       # Sorties utiles
```

> **Code complet disponible** : [`infra/terraform/main.tf`](./infra/terraform/main.tf)

---

## **3.2 Variables clés (`terraform.tfvars`)**

```hcl
vpc_id        = "vpc-0ebcdb39f7a526ef9"
ami_id        = "ami-0e207c18bb303cc68"  # Ubuntu 24.04 LTS
instance_type = "t3.micro"
my_ip         = "78.203.39.33/32"

subnets_cidr_block = {
  public = {
    cidr   = "172.31.40.0/24"
    az     = "eu-west-3a"
    public = true
  }
  private = {
    cidr   = "172.31.201.0/24"
    az     = "eu-west-3a"
    public = false
  }
}

ssh_keys = {
  "td-j1-key-bastion" = "ssh-ed25519 AAAAC3... bastion"
  "td-j1-key-web"     = "ssh-ed25519 AAAAC3... web"
}
```

> **Ne jamais commiter `terraform.tfvars`**.

---

## **3.3 Commandes Terraform**

### **Initialisation**
```bash
terraform init
```

**Sortie attendue** :
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

---

### **Formatage**
```bash
terraform fmt
```

Formate automatiquement tous les fichiers `.tf` selon le style officiel HashiCorp.

---

### **Validation**
```bash
terraform validate
```

**Sortie attendue** :
```
Success! The configuration is valid.
```

---

### **Planification**
```bash
terraform plan
```

**Sortie attendue (extrait)** :
```
Plan: 10 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + test_wxm_bastion_public_ip = (known after apply)
  + test_wxm_cible_private_ip  = (known after apply)
  + test_wxm_ssh_bastion       = (known after apply)
  + test_wxm_ssh_cible         = (known after apply)
...
```

---

### **Application**
```bash
terraform apply
```

Taper `yes` pour confirmer. Durée estimée : **3–5 minutes** (le NAT Gateway prend ~2 min).

**Sortie attendue (extrait)** :
```
aws_instance.test_wxm_bastion: Creation complete
aws_instance.test_wxm_cible: Creation complete

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:
bastion_public_ip  = "xx.xxx.xx.xx"
cible_private_ip   = "172.31.xxx.xx"
```

---

## **3.4 Vérification post-déploiement**

```bash
# Vérifier que le bastion a une IP publique
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=test_wxm-bastion" \
  --query "Reservations[*].Instances[*].[PublicIpAddress,PrivateIpAddress,State.Name]" \
  --output table --region eu-west-3

# Vérifier que la cible N'a PAS d'IP publique
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=test_wxm-cible" \
  --query "Reservations[*].Instances[*].[PublicIpAddress,PrivateIpAddress,State.Name]" \
  --output table --region eu-west-3
```

**Résultat attendu** :
```
Bastion : PublicIpAddress = xx.xxx.xx.xx  ✅
Cible   : PublicIpAddress = None          ✅
```

---

## **Réponses — Questions Partie 2**

**Q1. Les deux instances sont dans un sous-réseau public : laquelle est joignable depuis Internet, et pourquoi ?**

Seul le **bastion** est joignable depuis Internet. Bien que les deux instances soient dans un sous-réseau public (route vers IGW), seul le bastion a reçu une **IP publique** (`associate_public_ip_address = true`). Sans IP publique, la cible n'a aucune adresse routable sur Internet — l'IGW ne peut pas lui transmettre de paquets entrants.

**Q2. Comment atteindre la cible puisqu'elle n'a pas d'IP publique ?**

On passe par le **bastion comme rebond SSH**. Le bastion est accessible depuis Internet, et depuis lui on peut atteindre la cible via son **IP privée** (`172.31.x.x`) car les deux instances sont dans le même VPC. C'est le pattern classique **Jump Host / Bastion Host**.

---

# **4. Security Groups**

## **4.1 Architecture des Security Groups**

```
Internet
   │
   │ SSH (port 22) depuis 78.203.39.33/32 uniquement
   ▼
┌─────────────┐
│   BASTION   │  sg-bastion
│  IP publique│──────────────────┐
└─────────────┘                  │ SSH (22) + ICMP
                                 │ source = sg-bastion
                            ┌────▼────────┐
                            │   CIBLE     │  sg-cible
                            │  IP privée  │
                            └─────────────┘
```

## **4.2 Configuration Terraform (extrait)**

Les Security Groups sont définis dans `main.tf` :

> **Voir** : [`main.tf` — Section 4 & 5](./infra/terraform/main.tf)

Points clés :
- `sg-bastion` : SSH entrant **uniquement depuis `var.my_ip`**
- `sg-cible` : SSH + ICMP entrants **uniquement depuis `sg-bastion`** (référence par ID de SG, pas par CIDR)

---

## **4.3 Connexion SSH via ssh-agent**

### **Pourquoi ssh-agent ?**

`ssh-agent` garde les clés privées en mémoire pour éviter de retaper la passphrase. Le **forwarding d'agent** (`-A`) permet au bastion d'utiliser votre clé locale pour se connecter à la cible — **sans copier la clé privée sur le bastion**.

```bash
# Démarrer l'agent SSH
eval "$(ssh-agent -s)"

# Ajouter les deux clés
ssh-add ~/.ssh/td-j1-key-bastion
ssh-add ~/.ssh/td-j1-key-web

# Vérifier les clés chargées
ssh-add -l
```

**Sortie attendue** :
```
256 SHA256:xxxx bastion (ED25519)
256 SHA256:yyyy web (ED25519)
```

### **Connexion au bastion**

```bash
ssh -A -i ~/.ssh/td-j1-key-bastion ubuntu@xx.xxx.xx.xx
```

> `-A` : active le forwarding d'agent (indispensable pour rebondir vers la cible)

### **Depuis le bastion, connexion à la cible**

```bash
# Depuis le bastion (grâce au forwarding d'agent, pas besoin de -i)
ssh ubuntu@172.31.xxx.xx
```

### **Test ICMP (ping)**

```bash
# Depuis le bastion
ping -c 4 172.31.xxx.xx
```

**Sortie attendue** :
```
PING 172.31.xxx.xx: 56 data bytes
64 bytes from 172.31.xxx.xx: icmp_seq=0 ttl=64 time=0.4 ms
...
4 packets transmitted, 4 received, 0% packet loss
```

---

## **Réponses — Questions Partie 3**

**Q1. Pourquoi définit-on la source du sg-cible comme « sg-bastion » plutôt qu'une plage d'IP ?**

Parce que l'**IP privée du bastion peut changer** (redémarrage, remplacement d'instance). En référençant le SG, la règle reste valide quel que soit l'IP du bastion — tout membre du `sg-bastion` est automatiquement autorisé. C'est plus robuste et plus sécurisé qu'une plage CIDR.

**Q2. Vous n'avez autorisé que l'entrée SSH ; pourquoi la réponse repart-elle sans règle de sortie explicite ?**

Les **Security Groups sont stateful** : ils tracent les connexions établies. Si un paquet entrant est autorisé, le trafic retour correspondant est **automatiquement autorisé** sans règle de sortie explicite. C'est la différence fondamentale avec les NACLs qui sont stateless.

---

# **5. NACL (pare-feu de sous-réseau, stateless)**

## **5.1 Configuration Terraform**

La NACL est définie dans `main.tf` :

> **Voir** : [`main.tf` — Section 6](./infra/terraform/main.tf)

**Règles configurées** :

| Direction | N° | Protocole | Ports | Source/Dest | Action |
|-----------|-----|-----------|-------|-------------|--------|
| Entrée | 100 | TCP | 22 | 0.0.0.0/0 | ALLOW |
| Entrée | 120 | ICMP | - | 0.0.0.0/0 | ALLOW |
| Entrée | 130 | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW |
| Sortie | 100 | TCP | 80 | 0.0.0.0/0 | ALLOW |
| Sortie | 110 | TCP | 443 | 0.0.0.0/0 | ALLOW |
| Sortie | 120 | TCP | 22 | 0.0.0.0/0 | ALLOW |
| Sortie | 130 | ICMP | - | 0.0.0.0/0 | ALLOW |
| Sortie | 140 | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW |

---

## **5.2 Démonstration du piège stateless**

**Sans la règle de sortie ports éphémères (ce qui se passerait)** :
```
Client → [SYN] → NACL entrée 100 → ✅ autorisé → EC2
EC2    → [SYN-ACK] → NACL sortie → ❌ bloqué (pas de règle éphémère)
# Résultat : connexion SSH jamais établie (timeout)
```

**Avec la règle de sortie 1024-65535** :
```
Client → [SYN] → NACL entrée 100 → ✅ → EC2
EC2    → [SYN-ACK] → NACL sortie 140 → ✅ → Client
# Résultat : connexion SSH établie ✅
```

---

## **Réponses — Questions Partie 4**

**Q1. Vous vous connectez au port 22 : pourquoi faut-il autoriser en sortie la plage 1024–65535 et non le port 22 ?**

Quand le client initie une connexion SSH vers le port 22, le **système d'exploitation du client choisit aléatoirement un port source éphémère** (entre 1024 et 65535, ex: `54823`). La réponse du serveur repart vers ce port éphémère — pas vers le port 22. Il faut donc autoriser en sortie toute la plage 1024-65535 pour que les réponses puissent atteindre le client.

**Q2. En une phrase, quelle est la différence de comportement entre un Security Group et une NACL ?**

Un **Security Group est stateful** (le trafic retour est automatiquement autorisé), tandis qu'une **NACL est stateless** (chaque sens du trafic doit être explicitement autorisé, y compris les ports éphémères de retour).

---

# **6. Défense en profondeur : NACL + Security Group**

## **6.1 Principe**

```
Internet
   │
   ▼
[NACL] ← Filtre niveau sous-réseau (stateless, évalué en premier)
   │
   ▼
[Security Group] ← Filtre niveau instance (stateful)
   │
   ▼
[EC2 Instance]
```

**Un paquet doit franchir les DEUX filtres.** Le plus restrictif l'emporte.

## **6.2 Test — Règle DENY en NACL**

Pour illustrer, on ajouterait temporairement une règle DENY n°90 (priorité plus haute que la règle ALLOW n°100) :

```bash
# Récupérer l'ID de la NACL créée par Terraform
aws ec2 describe-network-acls \
  --filters "Name=tag:Name,Values=test_wxm-nacl" \
  --query "NetworkAcls[0].NetworkAclId" \
  --output text \
  --region eu-west-3

# Ajout d'une règle DENY prioritaire (n°90 < 100)
aws ec2 create-network-acl-entry \
  --network-acl-id acl-XXX \
  --rule-number 90 \
  --protocol 6 \
  --port-range From=22,To=22 \
  --cidr-block 78.203.39.33/32 \
  --rule-action deny \
  --ingress \
  --region eu-west-3

# Résultat : SSH bloqué même si le SG autorise toujours notre IP
# ssh ubuntu@xx.xxx.xx.xx → timeout

# Suppression de la règle DENY pour rétablir l'accès
aws ec2 delete-network-acl-entry \
  --network-acl-id acl-XXX \
  --rule-number 90 \
  --ingress \
  --region eu-west-3
```

---

## **Réponses — Questions Partie 5**

**Q1. Si le Security Group autorise un flux mais que la NACL le refuse, le trafic passe-t-il ?**

**Non.** La NACL est évaluée **avant** le Security Group (au niveau du sous-réseau). Si la NACL refuse le paquet, il est abandonné avant même d'atteindre l'instance — le Security Group n'est jamais consulté.

**Q2. Citez un avantage concret d'avoir deux couches de filtrage plutôt qu'une seule.**

En cas de **mauvaise configuration d'un Security Group** (ex: règle SSH `0.0.0.0/0` ajoutée par erreur), la NACL peut bloquer le trafic non désiré au niveau du sous-réseau et limiter l'exposition. Les deux couches sont indépendantes — compromettre l'une ne compromet pas l'autre.

---

# **7. Déploiement applicatif avec Ansible**

## **7.1 Pourquoi Ansible ?**

Une fois l'infrastructure provisionnée par Terraform, **Ansible prend le relais** pour configurer les instances : installer des paquets, démarrer des services, déployer des fichiers de configuration.

| Terraform | Ansible |
|-----------|---------|
| Crée l'infrastructure (VPC, EC2, SG...) | Configure les instances (nginx, users...) |
| Déclaratif, état géré | Procédural, idempotent |
| Ne se connecte pas aux instances | Se connecte via SSH |

---

## **7.2 Prérequis**

```bash
# Vérifier qu'Ansible est installé
ansible --version

# Installer si nécessaire (Ubuntu/Debian)
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

---

## **7.3 Structure du projet Ansible**

```
td-jour1/
├── infra/
│   └── terraform/    # Terraform (déjà fait)
│   └──ansible/
        ├── inventory.ini    # Cibles SSH
        └── nginx.yml        # Playbook d'installation nginx
```

---

## **7.4 Récupérer les IPs depuis Terraform**

```bash
# IP publique du bastion
terraform output test_wxm_bastion_public_ip

# IP privée de la cible
terraform output test_wxm_cible_private_ip
```

---

## **7.5 Inventaire Ansible (`inventory.ini`)**

```ini
[bastion]
xx.xxx.xx.xx ansible_user=ubuntu \
  ansible_ssh_private_key_file=~/.ssh/td-j1-key-bastion

[cible]
172.31.xxx.xx ansible_user=ubuntu \
  ansible_ssh_private_key_file=~/.ssh/td-j1-key-web \
  ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -i ~/.ssh/td-j1-key-bastion -W %h:%p -o StrictHostKeyChecking=no ubuntu@13.38.73.217"'
```

> **ProxyJump** : Ansible se connecte à la cible **via le bastion** sans jamais copier de clé privée sur le bastion.

---

## **7.6 Vérification de la connectivité**

```bash
# S'assurer que l'agent SSH a les deux clés
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/td-j1-key-bastion
ssh-add ~/.ssh/td-j1-key-web

# Tester la connectivité Ansible vers les deux hôtes
ansible -i inventory.ini all -m ping
```

**Sortie attendue** :
```
xx.xxx.xx.xx | SUCCESS => {
    "ping": "pong"
}
172.31.xxx.xx | SUCCESS => {
    "ping": "pong"
}
```

---

## **7.7 Playbook nginx (`nginx.yml`)**

```yaml
---
- name: Installer et démarrer nginx sur la cible
  hosts: cible
  become: true

  tasks:
    - name: Mettre à jour le cache apt
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Installer nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    - name: Démarrer et activer nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true

    - name: Vérifier que nginx répond
      ansible.builtin.uri:
        url: http://localhost
        status_code: 200
      register: result

    - name: Afficher le statut
      ansible.builtin.debug:
        msg: "nginx répond avec le code {{ result.status }}"
```

---

## **7.8 Exécution du playbook**

```bash
ansible-playbook -i inventory.ini nginx.yml
```

**Sortie attendue** :
```
PLAY [Installer et démarrer nginx sur la cible] ******************************

TASK [Mettre à jour le cache apt] ********************************************
changed: [172.31.xxx.xx]

TASK [Installer nginx] *******************************************************
changed: [172.31.xxx.xx]

TASK [Démarrer et activer nginx] *********************************************
changed: [172.31.xxx.xx]

TASK [Vérifier que nginx répond] *********************************************
ok: [172.31.xxx.xx]

TASK [Afficher le statut] ****************************************************
ok: [172.31.xxx.xx] => {
    "msg": "nginx répond avec le code 200"
}

PLAY RECAP *******************************************************************
172.31.xxx.xx : ok=5  changed=3  unreachable=0  failed=0
```

---

## **7.9 Vérification manuelle depuis le bastion**

```bash
# Se connecter au bastion
ssh -A -i ~/.ssh/td-j1-key-bastion ubuntu@xx.xxx.xx.xx

# Depuis le bastion, vérifier nginx sur la cible
curl http://172.31.xxx.xx
```

**Sortie attendue** :
```html
<html><body><h1>hello</h1></body></html>
```

> **Note** : nginx n'est accessible que depuis le bastion (IP privée). La cible n'a pas d'IP publique et le SG ne laisse pas passer le port 80 depuis Internet — c'est intentionnel.

---

# **8. Nettoyage avec Terraform**

## **8.1 Destruction de l'infrastructure**

```bash
terraform destroy
```

Taper `yes` pour confirmer.

**Sortie attendue** :
```
aws_instance.test_wxm_cible: Destroying...
aws_instance.test_wxm_bastion: Destroying...
...
Destroy complete! Resources: 10 destroyed.
```

## **8.2 Vérification post-destruction**

```bash
# Vérifier qu'aucune instance ne subsiste
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=test_wxm-*" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name]" \
  --output table --region eu-west-3

# Vérifier qu'aucun SG personnalisé ne subsiste
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=test_wxm-*" \
  --query "SecurityGroups[*].[GroupId,GroupName]" \
  --output table --region eu-west-3

# Vérifier que l'EIP est libérée (éviter les coûts)
aws ec2 describe-addresses \
  --query "Addresses[*].[PublicIp,AssociationId]" \
  --output table --region eu-west-3
```

**Résultat attendu** : Toutes les requêtes retournent des listes vides.

> **Le VPC par défaut, ses sous-réseaux et son IGW sont préservés** — Terraform n'a créé que ses propres ressources, il ne détruit que celles-ci.

---

# **9. Bilan — Bonnes pratiques retenues**

| Pratique | Pourquoi |
|----------|----------|
| **SSH restreint à `mon_IP/32`** | Réduit la surface d'attaque au strict minimum |
| **Bastion comme seul point d'entrée** | Isole les serveurs internes d'Internet |
| **Source SG → SG** (pas CIDR) | Résistant aux changements d'IP privées |
| **Clé dédiée par instance** | Compromission d'une clé n'affecte pas l'autre |
| **ssh-agent + forwarding** | Pas de clé privée copiée sur le bastion |
| **ProxyJump Ansible** | Ansible atteint la cible sans IP publique |
| **NACL + SG (défense en profondeur)** | Deux couches indépendantes = résilience |
| **Ports éphémères en sortie NACL** | Indispensable pour le trafic retour (stateless) |
| **`terraform destroy` propre** | Évite les coûts résiduels et les ressources orphelines |
