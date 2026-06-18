output "site_url" {
  description = "URL publique du formulaire web"
  value       = "http://${aws_lb.public.dns_name}"
}

output "public_alb_dns" {
  description = "DNS de l'ALB public"
  value       = aws_lb.public.dns_name
}

output "internal_alb_dns" {
  description = "DNS de l'ALB interne"
  value       = aws_lb.internal.dns_name
}

output "rds_endpoint" {
  description = "Endpoint RDS PostgreSQL"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Port PostgreSQL"
  value       = aws_db_instance.postgres.port
}

output "rds_secret_name" {
  description = "Nom du secret Secrets Manager contenant les identifiants RDS"
  value       = aws_secretsmanager_secret.rds_password.name
}

output "vpc_id" {
  description = "ID du VPC existant utilise"
  value       = data.aws_vpc.existing.id
}
