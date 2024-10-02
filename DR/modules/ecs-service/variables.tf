variable "default_tags" {}
variable "app_name" {}
variable "ecs_cluster_name" {}
variable "ecs_task_definition_arn" {}
variable "vpc_id" {
    type    = string
    default = "vpc-0749076e30328d90f"
    description = "The default DR VPC"
}
variable "private_subnet_id_1" {
    type    = string
    default = "subnet-0947a24e67db7f9c1"
    description = "The default private subnet az1"
}
variable "private_subnet_id_2" {
    type    = string
    default = "subnet-0cbfcc3717d0cc690"
    description = "The default private subnet az2"
}
variable "public_subnet_id_1" {
    type    = string
    default = "subnet-0157542b2c44e7f0a"
    description = "The default public subnet az1"
}
variable "public_subnet_id_2" {
    type    = string
    default = "subnet-026d24ff8339f945c"
    description = "The default public subnet az2"
}

