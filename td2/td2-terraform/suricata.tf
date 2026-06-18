resource "aws_security_group" "sonde" {
  name        = "${var.project_prefix}-sg-sonde"
  description = "Sonde Suricata : SSH et ICMP depuis le bastion"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description     = "SSH depuis le bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "ICMP depuis le bastion"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Sortie autorisee"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-sg-sonde"
  })
}

resource "aws_instance" "sonde_suricata" {
  ami                    = var.vm_image
  instance_type          = var.vm_instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.sonde.id]

  user_data = templatefile("${path.module}/user_data_suricata.sh.tftpl", {
    ssh_user       = var.ssh_user
    ssh_public_key = local.ssh_public_key
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-sonde-suricata"
    Role = "suricata"
  })
}
