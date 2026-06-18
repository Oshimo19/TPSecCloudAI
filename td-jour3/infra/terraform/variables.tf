# Terraform variables.tf
# Declaration des variables

variable "aws_region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-3"
}

variable "student_id" {
  description = "Numero d etudiant (0-99) : noms et CIDR uniques"
  type        = number
}

variable "my_ip" {
  description = "IP publique en /32 pour restreindre l'accès SSH"
  type        = string
  sensitive   = false
}

# --- Donnees du VPC ---
variable "vpc_cidr" {
  description = "CIDR du VPC"
  default     = "10.172.0.0/16"
}

variable "azs" {
  description = "Zones de disponibilité"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

# --- CIDR des subnets (8 subnets, 4 paires sur 2 AZ) ---
variable "public_subnet_cidrs" {
  description = "CIDR des subnets publics"
  type        = list(string)
  default     = ["10.172.0.0/24", "10.172.1.0/24"]
}

variable "web_subnet_cidrs" {
  description = "CIDR des subnets web (privés)"
  type        = list(string)
  default     = ["10.172.10.0/24", "10.172.11.0/24"]
}

variable "app_subnet_cidrs" {
  description = "CIDR des subnets app (privés)"
  type        = list(string)
  default     = ["10.172.20.0/24", "10.172.21.0/24"]
}

variable "data_subnet_cidrs" {
  description = "CIDR des subnets data/RDS (privés)"
  type        = list(string)
  default     = ["10.172.30.0/24", "10.172.31.0/24"]
}


# --- Données pour les instances EC2 ---
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

# --- Données de la base RDS ---
variable "db_username" {
  description = "Nom d'utilisateur RDS"
  default     = "appuser"
}
variable "db_password" {
  description = "Mot de passe RDS"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nom de la base RDS"
  type        = string
  default     = "signupdb"
}
