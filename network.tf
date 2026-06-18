# Terraform network.tf
# Subnets publics/web/app + NAT + routes

# --- Subnets PUBLICS ---
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = data.aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.prefix}-public-${var.azs[count.index]}"
  }
}

# --- Subnets WEB (prives) ---
resource "aws_subnet" "web" {
  count                   = length(var.azs)
  vpc_id                  = data.aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.web_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-web-${var.azs[count.index]}"
  }
}

# --- Subnets APP (prives) ---
resource "aws_subnet" "app" {
  count                   = length(var.azs)
  vpc_id                  = data.aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.app_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-app-${var.azs[count.index]}"
  }
}

# --- EIP pour NAT Gateways ---
resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"

  tags = {
    Name = "${local.prefix}-nat-eip-${count.index}"
  }
}

# --- NAT Gateways ---
resource "aws_nat_gateway" "nat" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.prefix}-natgw-${var.azs[count.index]}"
  }
}

# --- Route table PUBLIQUE ---
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.main.id
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

# --- Route tables PRIVEES ---
resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "${local.prefix}-rt-private-${var.azs[count.index]}"
  }
}

# --- Associations WEB ---
resource "aws_route_table_association" "web" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.web[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- Associations APP ---
resource "aws_route_table_association" "app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
