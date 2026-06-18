# Terraform data.tf
# Prefix pour les composants

locals {
  prefix = "wrm-td3-${var.student_id}"
}