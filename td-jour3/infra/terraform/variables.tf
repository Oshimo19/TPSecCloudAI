# Terraform variables.tf
# Declaration des variables

variable "aws_region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_id" {
  description = "ID du VPC cible (eu-west-3)"
  type        = string
  default     = "vpc-0ebcdb39f7a526ef9"
}

variable "student_id" {
  description = "Numero d etudiant (0-99) : noms et CIDR uniques"
  type        = number
}

variable "my_ip" {
  description = "IP publique en /32 pour restreindre l'accès SSH"
  type        = string
  sensitive   = true
}

variable "azs" {
  description = "Zones de disponibilite"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

# --- CIDR des subnets (VPC existant 172.31.0.0/16) ---
# 172.31.0.0/20, 16.0/20, 32.0/20 = subnets par defaut AWS
variable "public_subnet_cidrs" {
  description = "CIDR des subnets publics (NAT + ALB public)"
  type        = list(string)
  default     = ["172.31.48.0/24", "172.31.49.0/24"] # deja crees, OK
}

variable "web_subnet_cidrs" {
  description = "CIDR des subnets web (prives)"
  type        = list(string)
  default     = ["172.31.64.0/24", "172.31.65.0/24"] # deja crees, OK
}

variable "app_subnet_cidrs" {
  description = "CIDR des subnets app (prives)"
  type        = list(string)
  # CHANGE : 96.0 (td-data-0) et 97.0 etaient en conflit
  # 160.0 et 161.0 verifies LIBRES
  default = ["172.31.160.0/24", "172.31.161.0/24"]
}

# --- Donnees pour les instances EC2 ---
variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI Ubuntu 24.04 AMD64"
  type        = string
  default     = "ami-0e207c18bb303cc68"
}

variable "ssh_user" {
  description = "Utilisateur par defaut pour les instances Ubuntu"
  type        = string
  default     = "ubuntu"
}

# --- Identifiants RDS ---
variable "db_secret_name" {
  description = "Nom du secret dans Secrets Manager"
  type        = string
  default     = "td-ipssi-rds-v2/password"
}

variable "db_name" {
  description = "Nom de la base PostgreSQL"
  type        = string
  default     = "td_ipssi"
}

variable "db_username" {
  description = "Nom d'utilisateur PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Mot de passe PostgreSQL"
  type        = string
  sensitive   = true
}

variable "rds_instance_identifier" {
  description = "Identifier de l'instance RDS existante (créée par rds-only)"
  type        = string
  default     = "td-ipssi-rds-v2"
}

variable "pepper" {
  description = "Poivre global pour le hachage HMAC-Argon2 (doit rester identique à vie)"
  type        = string
  sensitive   = true
}
