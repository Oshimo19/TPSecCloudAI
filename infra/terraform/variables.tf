# Terraform variables.tf - TP DevOps AWS Ansible Jenkins 
# Fichier de declaration des variables utilisees dans cet environnement de travail

variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "vpc_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type = string
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "subnets_cidr_block" {
  type = map(object({
    cidr   = string
    az     = string
    public = bool
  }))
}

variable "ssh_keys" {
  type = map(string)
}
