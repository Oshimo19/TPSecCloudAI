# Terraform outputs.tf

# ------------------
# Bastion
# ------------------

output "test_wxm_bastion_public_ip" {
  description = "IP publique du bastion"
  value       = aws_instance.test_wxm_bastion.public_ip
}

output "test_wxm_ssh_bastion" {
  description = "Commande SSH directe vers le bastion"
  value       = "ssh -i ~/.ssh/td-j1-key-bastion ${var.ssh_user}@${aws_instance.test_wxm_bastion.public_ip}"
}

# ------------------
# Cible
# ------------------

output "test_wxm_cible_private_ip" {
  description = "IP privee de la cible"
  value       = aws_instance.test_wxm_cible.private_ip
}

output "test_wxm_ssh_cible" {
  description = "Pivoting via bastion (nécessite ssh-agent)"
  value       = <<-EOT
    eval $(ssh-agent)
    ssh-add ~/.ssh/td-j1-key-bastion
    ssh-add ~/.ssh/td-j1-key-web
    ssh -J ubuntu@${aws_instance.test_wxm_bastion.public_ip} ubuntu@${aws_instance.test_wxm_cible.private_ip}
  EOT
}

