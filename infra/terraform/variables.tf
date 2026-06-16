variable "aws_region" {
  description = "Region par default"
  type        = string
  default     = "eu-west-3"
}
variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "vm_image" {
  description = "AMI de l'instance"
  type        = string
}

variable "vm_instance_type" {
  description = "Type de l'instance"
  type        = string
  default     = "t2.micro"
}


variable "my_ip" {
  description = "Adresse IP publique de l'utilisateur"
  type        = string
}


variable "subnet_cidr_block" {
  type        = string
  description = "CIDR du subnet utilisé pour les instances"
  default     = "172.31.240.0/24"
}