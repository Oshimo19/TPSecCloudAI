output "vm_ip_public" {
  description = "Adresse IP publique de la VM EC2"
  value       = aws_instance.walid_vm.public_ip
}
