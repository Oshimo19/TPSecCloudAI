locals {
  ssh_public_key = trimspace(file(var.ssh_public_key_path))

  common_tags = {
    Project = "TD2 J2 Suricata"
    Owner   = "Walid"
    TD      = "Jour2"
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_prefix}-sg-bastion"
  description = "SSH depuis mon IP uniquement"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "SSH depuis mon IP publique"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Sortie autorisee"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-sg-bastion"
  })
}

resource "aws_instance" "bastion" {
  ami                         = var.vm_image
  instance_type               = var.vm_instance_type
  subnet_id                   = data.aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data_ssh.sh.tftpl", {
    ssh_user       = var.ssh_user
    ssh_public_key = local.ssh_public_key
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-bastion"
    Role = "bastion"
  })
}
