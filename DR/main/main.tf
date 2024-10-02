terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"  
    }
  }
}
provider "aws" {
  region = "${var.region}"

  default_tags {
    tags = var.default_tags
  }
}


module "ecs" {
  source = "../modules/ecs"
  default_tags = var.default_tags
  app_name = var.app_name
}

module "task-definition" {
  source = "../modules/task-definition"
  default_tags = var.default_tags
  app_name = var.app_name
  region = var.region
  ecr_repo = var.ecr_repo
}

module "ecs-service" {
  source = "../modules/ecs-service"
  default_tags = var.default_tags
  app_name = var.app_name
  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_task_definition_arn = module.task-definition.ecs_task_definition_arn
}