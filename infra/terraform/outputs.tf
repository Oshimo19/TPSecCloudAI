# Terraform output.txt - Contient les sorties du main.tf

output "test_wxm_bastion_public_ip" {
  value = aws_instance.test_wxm_bastion.public_ip
}

output "test_wxm_ssh_bastion" {
  value = "ssh -i ~/.ssh/tp-key-bastion-2 ${var.ssh_user}@${aws_instance.test_wxm_bastion.public_ip}"
}
