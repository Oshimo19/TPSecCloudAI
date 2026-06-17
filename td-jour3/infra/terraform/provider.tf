# Terraform provider.tf
# Fichier provider AWS

terraform {
  # 1) Version minimale de Terraform
  required_version = ">= 1.5.0"

  # 2) Déclaration du provider AWS
  required_providers {
    aws = {
      source  = "hashicorp/aws" # editeur/nom du provider
      version = "~> 5.0"        #  version stable
    }
  }
}

# 3) Parametrage du provider AWS
provider "aws" {
  region = var.region
}
