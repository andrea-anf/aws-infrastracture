data "aws_ecr_repository" "sample_app" {
  name = "sample-app"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"
}
resource "aws_ecs_service" "sample_app" {
  name                               = var.project
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.sample_app.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 3
  launch_type                        = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_80.arn
    container_name   = var.project
    container_port   = var.app_port
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_container_instance.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false

  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project}-first-ecs-task-definition"
  network_mode             = "awsvpc"
  required_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_iam_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "${var.project}-first"
      image     = "${aws_ecr_repository.sample_app.repository_url}:latest"
      cpu       = var.cpu_units
      memory    = var.memory
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_security_group" "ecs_container_instance" {
  name        = "${var.project}-ecs-task-sg"
  description = "Security group for ECS task running on Fargate"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow ingress traffic from ALB on HTTP only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}_ECS_Task_SecurityGroup"
  }
}

# SG to allow traffic only from ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg"
  description = "allow inbound access only from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.load_balancer.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}

data "aws_iam_policy_document" "task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_iam_role" {
  name               = "${var.project}ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}