variable "aws_region" {
  description = "Region AWS utilisee pour le TD"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_id" {
  description = "ID du VPC existant a utiliser"
  type        = string
}

variable "public_subnet_id" {
  description = "ID du subnet existant utilise pour le bastion et la NAT Gateway"
  type        = string
}

variable "vm_image" {
  description = "AMI a utiliser pour les instances EC2"
  type        = string
}

variable "vm_instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

variable "my_ip" {
  description = "Votre IP publique en /32 pour autoriser SSH vers le bastion"
  type        = string
}

variable "ssh_user" {
  description = "Utilisateur Linux pour SSH/Ansible"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Chemin local vers la cle publique SSH a injecter via user_data"
  type        = string
  default     = "/root/.ssh/terraform-ipssi.pub"
}

variable "private_subnet_cidr" {
  description = "CIDR du subnet prive cree par Terraform"
  type        = string
  default     = "172.31.100.0/24"
}

variable "project_prefix" {
  description = "Prefixe des noms AWS"
  type        = string
  default     = "td2-walid"
}
