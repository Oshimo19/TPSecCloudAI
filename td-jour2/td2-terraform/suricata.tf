# Terraform suricata.tf - Deploiement sonde Suricata

# Security Group : SSH + ICMP depuis le bastion uniquement
resource "aws_security_group" "sonde" {
  name   = "${local.prefix}-sg-sonde"
  vpc_id = data.aws_vpc.default.id

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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-sg-sonde" }
}

# Instance sonde — pas de user_data, configuration déléguée à Ansible
resource "aws_instance" "sonde" {
  ami                         = var.sonde_ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.td2_subnets["public-a"].id
  vpc_security_group_ids      = [aws_security_group.sonde.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.sonde.key_name

  tags = { Name = "${local.prefix}-sonde" }
}

output "sonde_ip" {
  value = aws_instance.sonde.public_ip
}

output "sonde_private_ip" {
  value = aws_instance.sonde.private_ip
}
