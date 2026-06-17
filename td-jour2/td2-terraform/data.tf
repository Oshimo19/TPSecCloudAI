# Terraform data.tf

data "aws_vpc" "default" {
  default = true # le VPC par defaut (172.31.0.0/16)
}

data "aws_subnet" "public_a" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "eu-west-3a"
  # default_for_az    = true -> retire : pas de subnet par defaut dans ce compte
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

locals {
  prefix = "td2-${var.student_id}"
}
