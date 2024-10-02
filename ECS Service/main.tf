
###### ECS Service
# configure aws provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"  # Ensure this version matches the one compatible with your configurations
    }
  }
}
provider "aws" {
  region = "ap-south-1"

}

#########################

# Security Groups
resource "aws_security_group" "alb_security_group" {
  name        = "DR_CMS_BACKEND_ALB_SG"
  description = "internal_api_backend_alb_sg, allows HTTP 80, HTTPS 443"
  vpc_id      = "" //var VPC ID

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["10.1.0.0/16"]
  }

  ingress {
    description      = "https access"
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["10.1.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {

  }
}

resource "aws_security_group" "ecs_service_security_group" {
  name        = "DR_ECS_CMS_BACKEND_SG"
  description = "internal_api_backend_alb_sg, allows HTTP 80, HTTPS 443"
  vpc_id      = "" //var VPC ID

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["10.1.0.0/16"]
  }

  ingress {
    description      = "https access"
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["10.1.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {

  }
}


## ALB
resource "aws_lb" "example_alb" {
  name               = "DRTestALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]  # Replace with your security group
  subnets            = ["subnet-0157542b2c44e7f0a", "subnet-026d24ff8339f945c"] # Replace with your subnets

  enable_deletion_protection = false
}


# Target Group
resource "aws_lb_target_group" "my_target_group" {
  name     = "DR-Test-Backend-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0749076e30328d90f" //Change VPC ID
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 15
    unhealthy_threshold = 2
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = false
    cookie_duration = 86400
  }

  tags = {
    # Add any tags here if necessary
  }
}

# Listeners
resource "aws_lb_listener" "example_listener" {
  load_balancer_arn = aws_lb.example_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}


## ECS Service
resource "aws_ecs_service" "new_example_service" {
  name                               = "DRTestECSService"
  cluster                            = "DRTestCluster"
  task_definition                    = "arn:aws:ecs:ap-south-1:365909855731:task-definition/DRTestTaskDefinition:3"
  desired_count                      = 1
  # launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 0
  }

  network_configuration {
    assign_public_ip = false
    subnets          = ["subnet-0947a24e67db7f9c1", "subnet-0cbfcc3717d0cc690"] //var subnet id
    security_groups  = [aws_security_group.ecs_service_security_group.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "dr-pg-test-backend"
    container_port   = 80
  }

  enable_ecs_managed_tags             = true
  propagate_tags                      = "TASK_DEFINITION"
  health_check_grace_period_seconds   = 0
  deployment_maximum_percent          = 200
  deployment_minimum_healthy_percent  = 50

}

## Task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "drtestEcsTaskExecutionRole"
  path = "/"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
