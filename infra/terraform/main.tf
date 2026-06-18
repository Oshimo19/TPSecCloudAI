provider "aws" {
  region = var.aws_region
}

resource "aws_subnet" "rayane_serveur_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnet_cidr_block
  map_public_ip_on_launch = false
  tags = {
    Name = "rayane-serveur-subnet"
  }
}










resource "aws_security_group" "bastion_rayane_sg" {
  name        = "bastion-rayane-sg"
  description = "Security group for rayane_bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "rayane-sg_bastion"
  }
}




resource "aws_key_pair" "rayane_key" {
  key_name   = "rayane-key"
  public_key = file("~/.ssh/rayane-key.pub")
}
















resource "aws_security_group" "cible_sg" {
  name        = "rayane_cible_sg"
  description = "Security Group de la cible privee"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH uniquement depuis le bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_rayane_sg.id]
  }

  ingress {
    description     = "ICMP uniquement depuis le bastion"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.bastion_rayane_sg.id]
  }

  egress {
    description = "Tout le trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rayane_cible_sg"
  }
}

resource "aws_instance" "bastion" {
  ami                         = var.vm_image
  instance_type               = var.vm_instance_type
  subnet_id                   = aws_subnet.rayane_serveur_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_rayane_sg.id]
  key_name                    = "rayane-key"

  tags = {
    Name = "rayane-bastion"
  }
}

resource "aws_instance" "cible" {
  ami                         = var.vm_image
  instance_type               = var.vm_instance_type
  subnet_id                   = aws_subnet.rayane_serveur_subnet.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.cible_sg.id]
  key_name                    = "rayane-key"

  tags = {
    Name = "rayane-cible-privee"
  }
}