# Utilisation du VPC existant : aucune ressource reseau n'est creee ici.
# Terraform recupere le VPC et ses subnets existants.

data "aws_vpc" "existing" {
  id = var.vpc_id
}

locals {
  public_subnet_ids = [
    "subnet-0a4ffc843dad84a39", # eu-west-3a public
    "subnet-0dfbe2ac4fc1609b4"  # eu-west-3b public
  ]

  private_subnet_ids = [
    "subnet-0f47dcab00eb4caf9", # eu-west-3a private
    "subnet-0029267bd062fce86"  # eu-west-3b private
  ]
}
