resource "aws_ecs_cluster" "gamma_ecs_cluster" {
  name = "gamma-${terraform.workspace}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    "Name"        = "gamma-${terraform.workspace}-cluster"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_ecs_service" "apigw" {
  name            = "apigw-${terraform.workspace}-service"
  cluster         = aws_ecs_cluster.gamma_ecs_cluster.id
  task_definition = aws_ecs_task_definition.gamma-apigw.id
  launch_type     = "FARGATE"
  desired_count   = 1
  load_balancer {
    target_group_arn = var.api_tg_arn
    container_name   = "apigw-${terraform.workspace}"
    container_port   = 80
  }
  network_configuration {
    subnets          = var.public_subnets
    assign_public_ip = true
    security_groups  = [var.apigw_sg]
  }

  depends_on = [
    var.gamma_lb
  ]
}

resource "aws_ecs_task_definition" "gamma-apigw" {
  family                = "gamma-${terraform.workspace}-apigw-taskdef"
  container_definitions = <<TASK_DEFINITION
[
        {
            "name": "apigw-${terraform.workspace}",
            "image": "205325221225.dkr.ecr.ap-southeast-1.amazonaws.com/gamma-apigw:beta",
            "cpu": 0,
            "portMappings": [
                {
                    "name": "apigw-80-tcp",
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp",
                    "appProtocol": "http"
                }
            ],
            "essential": true,
            "environment": [
                {
                    "name": "ASPNETCORE_ENVIRONMENT",
                    "value": "beta"
                }
            ],
            "environmentFiles": [],
            "mountPoints": [],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/gamma-beta-apigw-taskdef",
                    "awslogs-region": "ap-southeast-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
TASK_DEFINITION

  network_mode             = "awsvpc"
  execution_role_arn       = var.gamma_execution_role
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_service" "users" {
  name            = "users-${terraform.workspace}-service"
  cluster         = aws_ecs_cluster.gamma_ecs_cluster.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.gamma-users.id
  desired_count   = 1
  load_balancer {
    target_group_arn = var.users_tg_arn
    container_name   = "users-${terraform.workspace}"
    container_port   = 3000
  }
  network_configuration {
    subnets          = var.public_subnets
    assign_public_ip = true
    security_groups  = [var.users_api_sg]
  }

  depends_on = [
    var.gamma_lb
  ]
}

resource "aws_ecs_task_definition" "gamma-users" {
  family                = "gamma-${terraform.workspace}-users-taskdef"
  container_definitions = <<TASK_DEFINITION
[
        {
            "name": "users-${terraform.workspace}",
            "image": "205325221225.dkr.ecr.ap-southeast-1.amazonaws.com/gamma-user-accounts-api:beta",
            "cpu": 0,
            "portMappings": [
                {
                    "name": "user-accounts-api-80-tcp",
                    "containerPort": 3000,
                    "hostPort": 3000,
                    "protocol": "tcp",
                    "appProtocol": "http"
                }
            ],
            "essential": true,
            "environment": [
                {
                    "name": "ASPNETCORE_ENVIRONMENT",
                    "value": "beta"
                }
            ],
            "mountPoints": [],
            "volumesFrom": [],
            "dockerLabels": {},
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/gamma-beta-userapis-taskdef",
                    "awslogs-region": "ap-southeast-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
TASK_DEFINITION

  network_mode             = "awsvpc"
  execution_role_arn       = var.gamma_execution_role
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_service" "game_engine" {
  name            = "gamma-gameegine-${terraform.workspace}-service"
  cluster         = aws_ecs_cluster.gamma_ecs_cluster.id
  task_definition = aws_ecs_task_definition.gamma-game-engine.id
  launch_type     = "FARGATE"
  desired_count   = 1
  load_balancer {
    target_group_arn = var.game_engine_tg_arn
    container_name   = "game-engine-api-${terraform.workspace}"
    container_port   = 8000
  }
  network_configuration {
    subnets          = var.public_subnets
    assign_public_ip = true
    security_groups  = [var.game_engine_sg]
  }

  depends_on = [
    var.gamma_lb
  ]
}

resource "aws_ecs_task_definition" "gamma-game-engine" {
  family                = "gamma-${terraform.workspace}-game-engine-taskdef"
  container_definitions = <<TASK_DEFINITION
[
        {
            "name": "game-engine-api-${terraform.workspace}",
            "image": "205325221225.dkr.ecr.ap-southeast-1.amazonaws.com/gamma-game-engine-api:beta",
            "cpu": 0,
            "portMappings": [
                {
                    "name": "game-engine-api-80-tcp",
                    "containerPort": 8000,
                    "hostPort": 8000,
                    "protocol": "tcp",
                    "appProtocol": "http"
                }
            ],
            "essential": true,
            "environment": [
                {
                    "name": "ASPNETCORE_ENVIRONMENT",
                    "value": "beta"
                }
            ],
            "mountPoints": [],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/gamma-beta-game-engine-taskdef",
                    "awslogs-region": "ap-southeast-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
TASK_DEFINITION

  network_mode             = "awsvpc"
  execution_role_arn       = var.gamma_execution_role
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}