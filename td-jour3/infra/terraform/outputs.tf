# Terraform outputs.tf
# DNS de ALB public, endpoint RDS....

output "rds_endpoint" {
  description = "Endpoint pour connexion depuis l'app tier"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true # on masque l output dans les logs Terraform via terraform plan / apply
}

output "rds_database_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Nom d'utilisateur admin"
  value       = aws_db_instance.postgres.username
  sensitive   = true # on masque l output dans les logs Terraform via terraform plan / apply
}

output "site_url" {
  description = "URL d'accès au formulaire d'inscription"
  value       = "http://${aws_lb.public.dns_name}"
}


# ═══════════════════════════════════════
# OUTPUTS
# ═══════════════════════════════════════

output "alb_internal_dns" {
  description = "DNS de l'ALB interne pour le tier web"
  value       = aws_lb.internal.dns_name
}
