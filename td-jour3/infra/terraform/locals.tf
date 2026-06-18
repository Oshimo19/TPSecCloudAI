# Terraform locals.tf
# Data sources pour réutiliser VPC, IGW, RDS et Secrets Manager existants

# --- Reseau existant (cree par rds-only) ---
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_internet_gateway" "main" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# --- RDS existante ---
data "aws_db_instance" "postgres" {
  db_instance_identifier = var.rds_instance_identifier
}

# --- Credentials RDS depuis Secrets Manager ---
data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = var.db_secret_name
}

# -- Prefix pour les composants ---
locals {
  prefix = "wrm-td3-${var.student_id}"

  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_password.secret_string)
  rds_endpoint   = data.aws_db_instance.postgres.endpoint
}
