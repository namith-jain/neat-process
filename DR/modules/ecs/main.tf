resource "aws_ecs_cluster" "cms_backend_cluster" {
  name = "${var.app_name}Cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = var.default_tags
}
