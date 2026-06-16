# Terraform output.tf

# ------------------
# Bastion
# ------------------

output "test_wxm_bastion_public_ip" {
  value = aws_instance.test_wxm_bastion.public_ip
}

output "test_wxm_ssh_bastion" {
  value = "ssh -i ~/.ssh/td-j1-key-bastion ${var.ssh_user}@${aws_instance.test_wxm_bastion.public_ip}"
}

# ------------------
# Serveur web
# ------------------

output "test_wxm_web_private_ip" {
  value = aws_instance.test_wxm_web.private_ip
}

output "test_wxm_ssh_web" {
  value = "ssh -i ~/.ssh/td-j1-key-web -o ProxyCommand=\"ssh -i ~/.ssh/td-j1-key-bastion -W %h:%p ${var.ssh_user}@${aws_instance.test_wxm_bastion.public_ip}\" ${var.ssh_user}@${aws_instance.test_wxm_web.private_ip}"
}

# ------------------
# ALB
# ------------------

output "test_wxm_web_url" {
  value = "http://${aws_lb.test_wxm_alb.dns_name}"
}
