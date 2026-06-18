variable "aws_region" {
  type        = string
  description = "Région AWS par défaut"
  default     = "eu-west-3"
}

variable "vpc_id" {
  type        = string
  description = "ID du VPC AWS"
}

variable "vm_image" {
  type        = string
  description = "ID de l'AMI à utiliser pour l'instance EC2"
}

variable "vm_instance_type" {
  type        = string
  description = "Type d'instance EC2"
  default     = "t2.micro"
}