# Terraform data.tf
# Prefix pour les composants + RDS PostgreSQL + DB subnet group

# -- Prefix utilise pour tager tous les composants --
locals {
  prefix = "wrm-td3-${var.student_id}"
}

# --- DB Subnet Group ---
resource "aws_db_subnet_group" "data" {
  name        = "${local.prefix}-db-subnet-group"
  description = "Subnet group pour RDS PostgreSQL - tier data"
  # [*] = splat pour récupérer tous les IDs des subnets data (multi-AZ requis)
  subnet_ids = aws_subnet.data[*].id # subnets privés "data"

  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}

# --- RDS PostgreSQL ---
resource "aws_db_instance" "postgres" {
  identifier = "${local.prefix}-postgres"
  engine     = "postgres"
  # commande : aws rds describe-db-engine-versions --engine postgres -> retourne : 16
  engine_version = "16"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.data.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]

  multi_az            = false   # haute disponibilité
  publicly_accessible = false   # JAMAIS exposée à Internet

  skip_final_snapshot      = false # OK en TD, PAS en production
  delete_automated_backups = false # OK en TD, PAS en production

  tags = {
    Name = "${local.prefix}-postgres"
  }
}
