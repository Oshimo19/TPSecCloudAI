# Terraform outputs.tf
# DNS de ALB public, endpoint RDS....

output "web_public_ips" {
  description = "IP publiques des instances web (accès Ansible / bastion)"
  value       = aws_instance.web[*].public_ip
}

output "web_private_ips" {
  value = aws_instance.web[*].private_ip
}

output "app_private_ips" {
  description = "IP privées des instances app (via ProxyJump web)"
  value       = aws_instance.app[*].private_ip
}

output "pepper" {
  value     = var.pepper
  sensitive = true
}

output "rds_endpoint" {
  description = "Endpoint pour connexion depuis l'app tier"
  value       = data.aws_db_instance.postgres.address
  sensitive   = true
}

output "rds_database_name" {
  description = "Nom de la base de données"
  value       = data.aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Nom d'utilisateur admin"
  value       = data.aws_db_instance.postgres.master_username
  sensitive   = true
}

output "site_url" {
  description = "URL d'accès au formulaire d'inscription"
  value       = "http://${aws_lb.public.dns_name}"
}

output "alb_internal_dns" {
  description = "DNS de l'ALB interne pour le tier web"
  value       = aws_lb.internal.dns_name
}
