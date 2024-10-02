variable "region" {}
variable "default_tags" {}
variable "app_name" {}
variable "ecr_repo" {}
variable "container_port" {
    type    = string
    default = "80"
    description = "The default contianer port"
}
variable "host_port" {
    type    = string
    default = "80"
    description = "The default host port"
}
variable "cpu" {
    type    = string
    default = "512"
    description = "The default CPU"
}
variable "memory" {
    type    = string
    default = "3072"
    description = "The default Memory"
}