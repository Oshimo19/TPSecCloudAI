# Terraform network.tf
# VPC, subnets, IGW, NAT, routes

# VPC par defaut (celui du formateur)
data "aws_vpc" "default_vpc" {
  id = var.vpc_id
}

# Sous-reseaux : Public-A, Public-B, et Prive
resource "aws_subnet" "td3_subnets" {
  for_each                = var.subnets_cidr_block
  vpc_id                  = data.aws_vpc.default_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public

  tags = {
    Name = "${local.prefix}-subnet-${each.key}"
  }
}

# IP élastique pour la NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway dans le sous-réseau PUBLIC
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.td2_subnets["public-a"].id
  tags          = { Name = "${local.prefix}-nat" }
}

# Table de routage privée → tout passe par la NAT
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "${local.prefix}-rt-prive" }
}

# Association subnet privé ↔ table de routage privée
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
