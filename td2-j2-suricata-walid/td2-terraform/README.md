# TD2 J2 Suricata - Terraform

Ce dossier provisionne l'infrastructure AWS du TD : bastion, subnet prive, NAT Gateway, instance privee et sonde Suricata.

## Variables utilisees

Les valeurs sont dans `terraform.tfvars` :

```hcl
aws_region       = "eu-west-3"
vpc_id           = "vpc-0ebcdb39f7a526ef9"
public_subnet_id = "subnet-095c2c562da7511cc"
vm_image         = "ami-0e207c18bb303cc68"
vm_instance_type = "t2.micro"
my_ip            = "80.214.56.151/32"
ssh_user         = "ubuntu"
ssh_public_key_path = "/root/.ssh/terraform-ipssi.pub"
```

## Important

Aucun `key_name` AWS n'est utilise. La cle publique SSH locale est injectee via `user_data`.

## Commandes

Depuis la racine du projet :

```bash
make pubkey
make init
make fmt
make validate
make plan
make apply
make inventory
make ping
make ansible
make test-alert
make alerts
```

A la fin du TD :

```bash
make destroy
```

La NAT Gateway est facturee si elle reste active.
