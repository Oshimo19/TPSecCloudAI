# Terraform security.tf
# Security groups

# --- ALB Public (Internet → Web) ---
resource "aws_security_group" "sg_alb_public" {
  name        = "${local.prefix}-sg-alb-public"
  description = "ALB public - HTTP depuis Internet"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-sg-alb-public"
  }
}

# --- Web Tier (ALB Public → Web EC2 instances) ---
resource "aws_security_group" "sg_web" {
  name        = "${local.prefix}-sg-web"
  description = "Web tier - HTTP depuis ALB public + SSH administrateur"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "HTTP depuis ALB public uniquement"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb_public.id]
  }

  ingress {
    description = "SSH depuis IP pour administration"
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
    Name = "${local.prefix}-sg-web"
  }
}

# --- ALB Internal (Web → App) ---
resource "aws_security_group" "sg_alb_internal" {
  name        = "${local.prefix}-sg-alb-internal"
  description = "ALB interne - HTTP depuis Web tier"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "HTTP depuis Web tier"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-sg-alb-internal"
  }
}

# --- App Tier (ALB Internal → App instances) ---
resource "aws_security_group" "sg_app" {
  name        = "${local.prefix}-sg-app"
  description = "App tier - HTTP depuis ALB interne + SSH depuis Web"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "HTTP depuis ALB interne"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb_internal.id]
  }

  ingress {
    description     = "SSH depuis les instances Web pour administration"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-sg-app"
  }
}

# --- SG RDS existant (créé par rds-only) ---
data "aws_security_group" "rds_existing" {
  name = "td-ipssi-rds-v2-sg"
}

# --- Règle : App tier → RDS (5432) ---
resource "aws_security_group_rule" "app_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_app.id
  security_group_id        = data.aws_security_group.rds_existing.id
  description              = "PostgreSQL depuis App tier"
}
