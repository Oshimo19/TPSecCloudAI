output "bastion_ip" {
  description = "Adresse IPv4 publique du bastion"
  value       = aws_instance.bastion.public_ip
}

output "private_ip" {
  description = "Adresse IPv4 privee de l'instance privee"
  value       = aws_instance.private.private_ip
}

output "sonde_private_ip" {
  description = "Adresse IPv4 privee de la sonde Suricata"
  value       = aws_instance.sonde_suricata.private_ip
}

output "nat_public_ip" {
  description = "Adresse IPv4 publique de la NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "ssh_bastion_command" {
  description = "Commande SSH pour se connecter au bastion"
  value       = "ssh -i /root/.ssh/terraform-ipssi ${var.ssh_user}@${aws_instance.bastion.public_ip}"
}
