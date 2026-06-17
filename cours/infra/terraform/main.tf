# Terraform main.tf - Bastion + Web (Ubuntu 24.04)
# VPC cible : vpc-0ebcdb39f7a526ef9

# --------------------------------------------------------
# 1. Subnets : Public
# --------------------------------------------------------

resource "aws_subnet" "test_wxm_subnets" {
  for_each                = var.subnets_cidr_block
  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public

  tags = {
    Name = "test_wxm-subnet-${each.key}"
  }
}

# --------------------------------------------------------
# 2. Internet Gateway existant du VPC
# --------------------------------------------------------

data "aws_internet_gateway" "test_wxm_existing_igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# --------------------------------------------------------
# 3. Route Table publique -> Internet Gateway
# --------------------------------------------------------

resource "aws_route_table" "test_wxm_public_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.test_wxm_existing_igw.id
  }

  tags = {
    Name = "test_wxm-public-rt"
  }
}

resource "aws_route_table_association" "test_wxm_public_assoc" {
  for_each       = var.subnets_cidr_block
  subnet_id      = aws_subnet.test_wxm_subnets[each.key].id
  route_table_id = aws_route_table.test_wxm_public_rt.id
}

# --------------------------------------------------------
# 4. Security Group Bastion (SSH depuis votre IP uniquement)
# --------------------------------------------------------

resource "aws_security_group" "test_wxm_sg_bastion" {
  name        = "test_wxm-sg-bastion"
  description = "SSH entrant depuis mon IP uniquement"
  vpc_id      = var.vpc_id

  # Entree : SSH depuis mon IP
  ingress {
    description = "SSH depuis mon IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Sortie : tout autorise
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test_wxm-sg-bastion"
  }
}

# --------------------------------------------------------
# 5. Security Group Cible (SSH + ICMP depuis bastion uniquement)
# --------------------------------------------------------

resource "aws_security_group" "test_wxm_sg_cible" {
  name        = "test_wxm-sg-cible"
  description = "SSH et ICMP depuis le bastion uniquement"
  vpc_id      = var.vpc_id

  # Entree : SSH depuis Bastion
  ingress {
    description     = "SSH depuis bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.test_wxm_sg_bastion.id]
  }

  # Entree : ICMP depuis Bastion
  ingress {
    description     = "ICMP depuis bastion"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.test_wxm_sg_bastion.id]
  }

  # Sortie : tout autorise
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test_wxm-sg-cible"
  }
}

# --------------------------------------------------------
# 6. NACL publique (bastion + cible)
# --------------------------------------------------------

resource "aws_network_acl" "test_wxm_nacl" {
  vpc_id = var.vpc_id
  subnet_ids = [
    for subnet in aws_subnet.test_wxm_subnets : subnet.id
  ]

  # -------------------------
  # INGRESS
  # -------------------------

  # SSH entrant
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # ICMP entrant (ping)
  ingress {
    rule_no    = 120
    protocol   = "icmp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    icmp_type  = -1
    icmp_code  = -1
    from_port  = 0
    to_port    = 0
  }

  # Ports éphémères entrants (réponses apt, SSH, etc.)
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # -------------------------
  # EGRESS
  # -------------------------

  # HTTP sortant (apt install)
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # HTTPS sortant (apt install)
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # SSH sortant (bastion -> cible)
  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # ICMP sortant (ping depuis bastion)
  egress {
    rule_no    = 130
    protocol   = "icmp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    icmp_type  = -1
    icmp_code  = -1
    from_port  = 0
    to_port    = 0
  }

  # Ports éphémères sortants (réponses SSH vers client)
  egress {
    rule_no    = 140
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "test_wxm-nacl"
  }
}

# --------------------------------------------------------
# 7. Cles SSH
# --------------------------------------------------------

resource "aws_key_pair" "test_wxm_bastion_key" {
  key_name   = "test_wxm-key-bastion"
  public_key = var.ssh_keys["td-j1-key-bastion"]
}

resource "aws_key_pair" "test_wxm_cible_key" {
  key_name   = "test_wxm-key-cible"
  public_key = var.ssh_keys["td-j1-key-web"]
}

# --------------------------------------------------------
# 8. Instance EC2 Bastion (IP publique)
# --------------------------------------------------------

resource "aws_instance" "test_wxm_bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.test_wxm_subnets["public"].id
  key_name                    = aws_key_pair.test_wxm_bastion_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.test_wxm_sg_bastion.id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  depends_on = [aws_route_table_association.test_wxm_public_assoc]

  tags = {
    Name = "test_wxm-bastion"
  }
}

# --------------------------------------------------------
# 9. Instance EC2 Cible (sans IP publique)
# --------------------------------------------------------

resource "aws_instance" "test_wxm_cible" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.test_wxm_subnets["public"].id
  key_name                    = aws_key_pair.test_wxm_cible_key.key_name
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.test_wxm_sg_cible.id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  depends_on = [aws_route_table_association.test_wxm_public_assoc]

  tags = {
    Name = "test_wxm-cible"
  }
}
