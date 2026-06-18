# Terraform network.tf
# VPC, subnets, IGW, NAT, routes

# -- VPC --
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.prefix}-vpc"
  }
}

# -- Interrnet Gateway (IGW) --
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id # ← CORRIGÉ : référence ton VPC créé, pas un data source
  tags   = { Name = "${local.prefix}-igw" }
}


# --- Subnets PUBLICS (un par AZ) ---
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.prefix}-public-${var.azs[count.index]}"
  }
}

# --- Subnets WEB (privés) ---
resource "aws_subnet" "web" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.web_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-web-${var.azs[count.index]}"
  }
}

# --- Subnets APP (privés) ---
resource "aws_subnet" "app" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.app_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-app-${var.azs[count.index]}"
  }
}

# --- Subnets DATA/RDS (privés) ---
resource "aws_subnet" "data" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.data_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-data-${var.azs[count.index]}"
  }
}

# --- EIP pour NAT Gateways ---
resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"

  tags = {
    Name = "${local.prefix}-nat-eip-${count.index}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# --- NAT Gateways (une par AZ, dans subnet public) ---
resource "aws_nat_gateway" "nat" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.prefix}-natgw-${var.azs[count.index]}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# --- Route table PUBLIQUE ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.prefix}-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Route tables PRIVÉES (une par AZ, pointe vers NAT locale) ---
resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "${local.prefix}-rt-private-${var.azs[count.index]}"
  }
}

# --- Associations : WEB ---
resource "aws_route_table_association" "web" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.web[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- Associations : APP ---
resource "aws_route_table_association" "app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- Associations : DATA ---
resource "aws_route_table_association" "data" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
