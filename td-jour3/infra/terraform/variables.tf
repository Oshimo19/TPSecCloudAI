# Terraform variables.tf

variable "region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_id" {
  description = "ID du VPC par défaut"
  type        = string
  default     = "eu-west-3"
}

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

variable "student_id" {
  description = "Numero d etudiant (0-99) : noms et CIDR uniques"
  type        = number
}

variable "my_ip" {
  description = "IP publique en /32 pour restreindre l'accès SSH"
  type        = string
  sensitive   = false
}

variable "subnets_cidr_block" {
  description = "Carte des sous-réseaux à créer (CIDR, AZ, public/privé)"
  type = map(object({
    cidr   = string
    az     = string
    public = bool
  }))
}
