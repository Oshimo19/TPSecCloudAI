resource "aws_security_group" "alb_public" {
  name        = "${var.project_prefix}-sg-alb-public"
  description = "ALB public : HTTP depuis Internet"
  vpc_id      = data.aws_vpc.existing.id

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

  tags = { Name = "${var.project_prefix}-sg-alb-public" }
}

resource "aws_security_group" "web" {
  name        = "${var.project_prefix}-sg-web"
  description = "Tier web : HTTP uniquement depuis ALB public"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description     = "HTTP depuis ALB public"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_prefix}-sg-web" }
}

resource "aws_security_group" "alb_internal" {
  name        = "${var.project_prefix}-sg-alb-internal"
  description = "ALB interne : HTTP uniquement depuis tier web"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description     = "HTTP depuis tier web"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_prefix}-sg-alb-internal" }
}

resource "aws_security_group" "app" {
  name        = "${var.project_prefix}-sg-app"
  description = "Tier app : HTTP uniquement depuis ALB interne"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description     = "HTTP depuis ALB interne"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_internal.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_prefix}-sg-app" }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_prefix}-sg-rds"
  description = "RDS PostgreSQL : 5432 uniquement depuis tier app"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description     = "PostgreSQL depuis tier app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_prefix}-sg-rds" }
}
