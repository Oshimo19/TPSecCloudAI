provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "bars_sg" {
  name   = "walid_bars_sg"
  vpc_id = var.vpc_id

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "walid_servers_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "172.31.120.0/24"

  tags = {
    Name = "walid_servers_subnet"
  }
}

resource "aws_key_pair" "walid_kp" {
  key_name   = "walid_kp"
  public_key = file("~/.ssh/terraform-ipssi.pub")
}

resource "aws_instance" "walid_vm" {
  ami                         = var.vm_image
  instance_type               = var.vm_instance_type
  subnet_id                   = aws_subnet.walid_servers_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bars_sg.id]
  key_name                    = aws_key_pair.walid_kp.key_name

  tags = {
    Name = "walid_vm"
  }
}