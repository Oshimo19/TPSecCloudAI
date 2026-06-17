# Terraform bastion.tf

resource "aws_security_group" "bastion" {
  name        = "${local.prefix}-sg-bastion"
  description = "SSH depuis mon IP uniquement"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # VOTRE_IP/32, jamais 0.0.0.0/0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-sg-bastion" }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.td2_subnets["public-a"].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion.key_name

  tags = { Name = "${local.prefix}-bastion" }
}

output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}
