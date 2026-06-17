# Terraform egress.tf

# Sous-réseau privé — CIDR unique par étudiant
resource "aws_subnet" "private" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.${100 + var.student_id}.0/24"
  availability_zone = "eu-west-3a"
  tags              = { Name = "${local.prefix}-prive" }
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

# Security Group : SSH entrant depuis le bastion uniquement
resource "aws_security_group" "private" {
  name   = "${local.prefix}-sg-prive"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description     = "SSH depuis le bastion uniquement"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-sg-prive" }
}

# Instance privée — clé dédiée, pas d'IP publique
resource "aws_instance" "private" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.private.key_name
  tags                        = { Name = "${local.prefix}-prive" }
}

output "private_ip" {
  value = aws_instance.private.private_ip
}
