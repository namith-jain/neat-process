variable "default_tags" {
  type = map(string)
  default = {
    Environment = "DR"
    Created     = "Terraform"
    Project     = "PG"
  }
}
variable "region" {}
variable "app_name" {}
variable "ecr_repo" {}
