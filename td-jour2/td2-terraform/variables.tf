# Terraform variables.tf

variable "region" {
  type        = string
  default     = "eu-west-3"
  description = "Région AWS cible"
}

variable "student_id" {
  description = "Numero d etudiant (0-99) : noms et CIDR uniques"
  type        = number
}

variable "my_ip" {
  description = "Votre IP publique en /32"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC cible (eu-west-3)"
  type        = string
  default     = "vpc-0ebcdb39f7a526ef9"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

variable "sonde_ami_id" {
  description = "AMI Ubuntu 24.04 LTS AMD64 (eu-west-3)"
  type        = string
  default     = "ami-0e207c18bb303cc68"
}

variable "subnets_cidr_block" {
  description = "Carte des sous-réseaux à créer (CIDR, AZ, public/privé)"
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
