resource "aws_db_subnet_group" "data" {
  name       = "${var.project_prefix}-db-subnet-group"
  subnet_ids = local.selected_subnet_ids

  tags = {
    Name = "${var.project_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_prefix}-postgres"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.data.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = var.rds_multi_az
  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.project_prefix}-postgres"
    Tier = "data"
  }
}

resource "aws_secretsmanager_secret" "rds_password" {
  name                    = "${var.project_prefix}/rds/password"
  description             = "Identifiants RDS du TD3"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_prefix}-rds-secret"
  }
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id

  secret_string = jsonencode({
    db_name  = var.db_name
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    engine   = "postgres"
  })
}
