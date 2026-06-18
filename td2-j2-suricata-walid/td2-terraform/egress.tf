resource "aws_subnet" "private" {
  vpc_id                  = data.aws_vpc.selected.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_subnet.public_a.availability_zone
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-private-subnet"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-eip-nat"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnet.public_a.id

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-nat"
  })
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.selected.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-rt-private"
  })
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "private" {
  name        = "${var.project_prefix}-sg-private"
  description = "Instance privee accessible en SSH depuis le bastion uniquement"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description     = "SSH depuis le bastion uniquement"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Sortie Internet via NAT Gateway"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-sg-private"
  })
}

resource "aws_instance" "private" {
  ami                    = var.vm_image
  instance_type          = var.vm_instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]

  user_data = templatefile("${path.module}/user_data_ssh.sh.tftpl", {
    ssh_user       = var.ssh_user
    ssh_public_key = local.ssh_public_key
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-private-instance"
    Role = "private"
  })
}
