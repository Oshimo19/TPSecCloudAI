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