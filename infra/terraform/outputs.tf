output "bastion_public_ip" {
  description = "IP publique du bastion"
  value       = aws_instance.bastion.public_ip
}

output "cible_private_ip" {
  description = "IP privée de la cible"
  value       = aws_instance.cible.private_ip
}