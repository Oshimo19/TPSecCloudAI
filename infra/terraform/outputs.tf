output "vm_ip_public" {
  value       = aws_instance.bastion.public_ip
  description = "Adresse IP publique de l'instance bastion"
}

output "cible_ip_private" {
  value       = aws_instance.cible.private_ip
  description = "Adresse IP privée de l'instance cible"
}


output "test_wxm_bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Adresse IP publique de l'instance bastion"
}