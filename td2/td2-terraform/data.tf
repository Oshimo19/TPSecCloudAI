data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "public_a" {
  id = var.public_subnet_id
}
