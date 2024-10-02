# configure aws provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"  
    }
  }
}
provider "aws" {
  region = "ap-south-1"
}


resource "aws_ecs_cluster" "my_cluster" {
  name = "DRTestCluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = {
    Created     = "20240326"
    Environment = "DR Test Cluster"
  }
}
