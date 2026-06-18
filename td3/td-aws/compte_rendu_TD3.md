# Compte rendu — TD3 AWS 3-tiers

## Objectif

Déployer une application web 3-tiers sur AWS avec Terraform :

- un ALB public devant le tier web ;
- un tier web Flask dans des subnets privés ;
- un ALB interne devant le tier applicatif ;
- un tier applicatif Flask dans des subnets privés ;
- une base RDS PostgreSQL Multi-AZ dans des subnets privés data ;
- une chaîne de Security Groups respectant le principe du moindre privilège.

## Commandes utilisées

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

## Outputs à compléter

```text
site_url = "A_COMPLETER"
internal_alb_dns = "A_COMPLETER"
rds_endpoint = "A_COMPLETER"
rds_secret_name = "A_COMPLETER"
```

## Tests réalisés

### Test 1 — Accès au formulaire

Commande :

```bash
terraform -chdir=td-aws output -raw site_url
```

Résultat :

```text
A_COMPLETER : le formulaire d'inscription s'affiche dans le navigateur.
```

### Test 2 — Inscription valide

Résultat :

```text
A_COMPLETER : une soumission valide renvoie un message de succès.
```

### Test 3 — Email en double

Résultat :

```text
A_COMPLETER : un email déjà utilisé renvoie une erreur 409 sans faire planter l'application.
```

### Test 4 — Accès direct à l'ALB interne depuis le poste local

Commande :

```bash
curl http://<internal_alb_dns>
```

Résultat attendu :

```text
Le curl échoue depuis le poste local, car l'ALB interne n'est joignable que depuis le VPC.
```

## Réponses aux questions

### Question 1 — Pourquoi une NAT Gateway par AZ ?

On déploie une NAT Gateway par AZ pour éviter qu'une seule AZ devienne un point de défaillance. Si une unique NAT Gateway est placée en AZ-a et que l'AZ-a tombe, les instances privées situées en AZ-b perdent aussi leur sortie Internet. Avec une NAT par AZ, chaque zone garde une sortie locale, ce qui améliore la disponibilité et évite une dépendance inter-AZ inutile.

### Question 2 — Un attaquant ayant compromis le tier web peut-il accéder directement à RDS ?

Non, pas directement. Le Security Group de RDS n'autorise le port 5432 que depuis le Security Group du tier applicatif. Le tier web n'est donc pas une source autorisée pour RDS. Même si une instance web est compromise, elle ne peut pas ouvrir directement une connexion PostgreSQL vers RDS tant que les Security Groups ne sont pas modifiés ou qu'un pivot via le tier applicatif n'est pas possible.

### Question 3 — Pourquoi `publicly_accessible = false` et subnet privé sont nécessaires ?

Les deux protections sont complémentaires. `publicly_accessible = false` empêche RDS d'obtenir une exposition publique. Le placement dans des subnets privés garantit aussi qu'il n'existe pas de route directe vers Internet. L'un sans l'autre est moins robuste : une mauvaise configuration réseau ou une modification future pourrait exposer la base. Les deux ensemble réduisent fortement le risque d'exposition.

### Question 4 — Pourquoi le `/health` de l'API ne doit pas interroger RDS ?

Le health check de l'ALB doit vérifier que l'application écoute et peut répondre rapidement. Si `/health` interroge RDS, une lenteur ou une indisponibilité temporaire de la base ferait marquer toutes les instances applicatives comme unhealthy, alors que le processus applicatif fonctionne encore. Cela peut provoquer une cascade d'indisponibilité.

### Question 5 — Chemin aller-retour d'une inscription

À l'aller, le navigateur envoie `GET /` ou `POST /signup` vers le DNS de l'ALB public. L'ALB public transmet la requête au target group web, puis à une instance EC2 du tier web. Lors du submit, le tier web appelle en HTTP interne `POST /api/signup` vers le DNS de l'ALB interne. L'ALB interne transmet la requête au target group app, puis à une instance EC2 du tier applicatif. L'application valide les données, hache le mot de passe et insère l'utilisateur dans RDS PostgreSQL via le port 5432.

Au retour, RDS confirme l'écriture à l'instance app. L'API renvoie une réponse JSON au tier web via l'ALB interne. Le tier web construit une page de confirmation, puis l'ALB public renvoie cette réponse au navigateur.

## Nettoyage

```bash
make destroy
```

Le nettoyage est obligatoire pour éviter les coûts liés à RDS, aux NAT Gateways, aux ALB et aux Elastic IP.
