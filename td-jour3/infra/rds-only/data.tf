# Terraform data.tf
# Déploiement RDS PostgreSQL avec AWS Secrets Manager

# ============================================================
# VARIABLES
# ============================================================

variable "db_name" {
  type    = string
  default = "mydb"
}

# ============================================================
# AWS SECRETS MANAGER
# ============================================================

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]<>?"
}

resource "aws_secretsmanager_secret" "rds_password" {
  name        = "td-ipssi-rds-v2/password"
  description = "Credentials RDS PostgreSQL"

  tags = {
    Name = "td-ipssi-rds-v2-secret"
  }
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id

  secret_string = jsonencode({
    username = "adminipssidb"
    password = random_password.db_password.result
    db_name  = var.db_name
  })
}

locals {
  db_credentials = jsondecode(aws_secretsmanager_secret_version.rds_password.secret_string)
}

# ============================================================
# VPC + IGW existants
# ============================================================

data "aws_vpc" "main" {
  id = "vpc-0ebcdb39f7a526ef9"
}

data "aws_internet_gateway" "main" {
  filter {
    name   = "attachment.vpc-id"
    values = ["vpc-0ebcdb39f7a526ef9"]
  }
}

# ============================================================
# SUBNETS - 2 AZ obligatoires pour RDS (instance sur eu-west-3a)
# ============================================================

resource "aws_subnet" "data_a" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "172.31.101.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "td-ipssi-rds-v2-subnet-a"
  }
}

resource "aws_subnet" "data_b" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "172.31.102.0/24"
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = true

  tags = {
    Name = "td-ipssi-rds-v2-subnet-b"
  }
}

# ============================================================
# DB SUBNET GROUP
# ============================================================

resource "aws_db_subnet_group" "data" {
  name       = "td-ipssi-rds-v2-subnet-group"
  subnet_ids = [aws_subnet.data_a.id, aws_subnet.data_b.id]

  tags = {
    Name = "td-ipssi-rds-v2-subnet-group"
  }
}

# ============================================================
# ROUTE TABLE
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.main.id
  }

  tags = {
    Name = "td-ipssi-rds-v2-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.data_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.data_b.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# SECURITY GROUP RDS
# ============================================================

resource "aws_security_group" "sg_rds" {
  name        = "td-ipssi-rds-v2-sg"
  description = "Security group RDS PostgreSQL - accessible publiquement"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
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
    Name = "td-ipssi-rds-v2-sg"
  }
}

# ============================================================
# RDS PostgreSQL
# ============================================================

resource "aws_db_instance" "postgres" {
  identifier     = "td-ipssi-rds-v2"
  engine         = "postgres"
  engine_version = "16.14"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = local.db_credentials.db_name
  username = local.db_credentials.username
  password = local.db_credentials.password

  availability_zone      = "eu-west-3a"
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.data.name

  multi_az            = false
  publicly_accessible = true
  skip_final_snapshot = true

  tags = {
    Name = "td-ipssi-rds-v2"
  }
}

# ============================================================
# OUTPUTS
# ============================================================

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "secret_arn" {
  value = aws_secretsmanager_secret.rds_password.arn
}

output "recuperer_credentials" {
  value = "aws secretsmanager get-secret-value --secret-id td-ipssi-rds-v2/password --query SecretString --output text | jq ."
}
