provider "aws" {
  region = var.aws_region
}

resource "aws_subnet" "walid_servers_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "walid_servers_subnet"
  }
}

resource "aws_key_pair" "walid_kp" {
  key_name   = "walid_kp"
  public_key = file("/root/.ssh/terraform-ipssi.pub")
}

resource "aws_security_group" "bastion_sg" {
  name        = "walid_bastion_sg"
  description = "Security Group du bastion"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH depuis mon IP uniquement"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Tout le trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "walid_bastion_sg"
  }
}

resource "aws_security_group" "cible_sg" {
  name        = "walid_cible_sg"
  description = "Security Group de la cible privee"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH uniquement depuis le bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description     = "ICMP uniquement depuis le bastion"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Tout le trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "walid_cible_sg"
  }
}

resource "aws_instance" "bastion" {
  ami                         = var.vm_image
  instance_type               = var.vm_instance_type
  subnet_id                   = aws_subnet.walid_servers_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = aws_key_pair.walid_kp.key_name

  tags = {
    Name = "walid-bastion"
  }
}

resource "aws_instance" "cible" {
  ami                         = var.vm_image
  instance_type               = var.vm_instance_type
  subnet_id                   = aws_subnet.walid_servers_subnet.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.cible_sg.id]
  key_name                    = aws_key_pair.walid_kp.key_name

  tags = {
    Name = "walid-cible-privee"
  }
}