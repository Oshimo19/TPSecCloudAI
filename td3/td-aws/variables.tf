variable "aws_region" {
  description = "Region AWS"
  type        = string
  default     = "eu-west-3"
}

variable "owner" {
  description = "Nom du proprietaire pour les tags"
  type        = string
  default     = "Walid"
}

variable "project_prefix" {
  description = "Prefixe unique pour nommer les ressources AWS"
  type        = string
  default     = "td3-walid"
}

# VPC existant fourni par l'enseignant / sandbox.
# Important : ce TD ne cree pas de nouveau VPC, subnet, NAT Gateway ou Internet Gateway.
variable "vpc_id" {
  description = "ID du VPC existant a utiliser"
  type        = string
}

variable "vm_image" {
  description = "AMI existante a utiliser pour les instances EC2"
  type        = string
}

variable "vm_instance_type" {
  description = "Type des instances EC2 web et app"
  type        = string
  default     = "t2.micro"
}

variable "my_ip" {
  description = "IP publique autorisee pour les tests depuis le poste local, au format x.x.x.x/32"
  type        = string
}

variable "db_name" {
  description = "Nom de la base PostgreSQL"
  type        = string
  default     = "signupdb"
}

variable "db_username" {
  description = "Utilisateur PostgreSQL"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Mot de passe RDS. A fournir via terraform.tfvars, jamais en clair dans Git."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe de l'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Stockage RDS en Go"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Version majeure PostgreSQL"
  type        = string
  default     = "16"
}

variable "rds_multi_az" {
  description = "Active RDS Multi-AZ pour la haute disponibilite"
  type        = bool
  default     = true
}
