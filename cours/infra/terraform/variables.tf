# Terraform variables.tf
# Fichier de déclaration des variables utilisées dans cet environnement de travail

variable "region" {
  type        = string
  default     = "eu-west-3"
  description = "Région AWS cible"
}

variable "vpc_id" {
  type        = string
  description = "ID du VPC par défaut"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Type d'instance EC2"
}

variable "ami_id" {
  type        = string
  description = "AMI Ubuntu 24.04 AMD64"
}

variable "ssh_user" {
  type        = string
  default     = "ubuntu"
  description = "Utilisateur SSH pour les instances Ubuntu"
}

variable "my_ip" {
  type        = string
  description = "IP publique en /32 pour restreindre l'accès SSH au bastion"
  sensitive   = false
}

variable "subnets_cidr_block" {
  type = map(object({
    cidr   = string
    az     = string
    public = bool
  }))
  description = "Carte des sous-réseaux à créer (CIDR, AZ, public/privé)"
}

variable "ssh_keys" {
  type        = map(string)
  description = "Paires de clés SSH publiques à importer dans AWS (nom => clé publique)"
  sensitive   = true
}
