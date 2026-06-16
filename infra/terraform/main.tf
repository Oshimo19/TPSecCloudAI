# Terraform main.tf - Bastion uniquement (Ubuntu 24.04)
# VPC existant : vpc-0ebcdb39f7a526ef9

# --------------------------------------------------------
# 1. Subnets : Public, Prive
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
  subnet_id      = aws_subnet.test_wxm_subnets["public"].id
  route_table_id = aws_route_table.test_wxm_public_rt.id
}

# --------------------------------------------------------
# 4. NACL -> subnet public
# --------------------------------------------------------

resource "aws_network_acl" "test_wxm_nacl" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.test_wxm_subnets["public"].id]

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

  # Réponses HTTP/HTTPS (ports éphémères TCP)
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # DNS UDP (réponses)
  ingress {
    rule_no    = 120
    protocol   = "udp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # DNS TCP (réponses)
  ingress {
    rule_no    = 121
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Ping entrant (ICMP)
  ingress {
    rule_no    = 130
    protocol   = "icmp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    icmp_type  = -1
    icmp_code  = -1
    from_port  = 0
    to_port    = 0
  }

  # -------------------------
  # EGRESS
  # -------------------------

  # HTTP sortant
  egress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # HTTPS sortant
  egress {
    rule_no    = 210
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # DNS sortant UDP
  egress {
    rule_no    = 220
    protocol   = "udp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  # DNS sortant TCP
  egress {
    rule_no    = 221
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  # Ports éphémères sortants
  egress {
    rule_no    = 230
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
# 5. Security Group Bastion
# --------------------------------------------------------

resource "aws_security_group" "test_wxm_sg_bastion" {
  name   = "test_wxm-sg"
  vpc_id = var.vpc_id

  tags = {
    Name = "test_wxm-sg"
  }
}

# Entrée SSH
resource "aws_security_group_rule" "test_wxm_bastion_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.test_wxm_sg_bastion.id
}

# Sortie : tout autorisé
resource "aws_security_group_rule" "test_wxm_bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.test_wxm_sg_bastion.id
}

# --------------------------------------------------------
# 6. Cle SSH Bastion
# --------------------------------------------------------

resource "aws_key_pair" "test_wxm_bastion_key" {
  key_name   = "test_wxm-key-bastion"
  public_key = var.ssh_keys["tp-key-bastion-2"]
}

# --------------------------------------------------------
# 7. Instance EC2 Bastion
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
