# Security Groups
resource "aws_security_group" "alb_security_group" {
  name        = "${var.app_name}_alb_security_group"
  description = "${var.app_name} ALB security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "https access"
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "all traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = var.default_tags
}

resource "aws_security_group" "ecs_service_security_group" {
  name        = "${var.app_name}_ecs_service_sg"
  description = "${var.app_name} ecs security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "https access"
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "all traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = var.default_tags
}

## ALB
resource "aws_lb" "app_alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]  # Replace with your security group
  subnets            = ["${var.public_subnet_id_1}", "${var.public_subnet_id_2}"] # Replace with your subnets

  enable_deletion_protection = false

  tags = var.default_tags
}


# Target Group
resource "aws_lb_target_group" "target_group" {
  name     = "${app_name}_tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
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

  tags = var.default_tags
}

# Listeners
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = var.default_tags
}


## ECS Service
resource "aws_ecs_service" "ecs_service" {
  name                               = "${var.app_name}_service"
  cluster                            = "${var.ecs_cluster_name}"
  task_definition                    = "${var.ecs_task_definition_arn}"
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
    subnets          = ["${var.private_subnet_id_1}", "${var.private_subnet_id_2}"]
    security_groups  = [aws_security_group.ecs_service_security_group.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-task"
    container_port   = 80
  }

  enable_ecs_managed_tags             = true
  propagate_tags                      = "TASK_DEFINITION"
  health_check_grace_period_seconds   = 0
  deployment_maximum_percent          = 200
  deployment_minimum_healthy_percent  = 50

  tags = var.default_tags

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
