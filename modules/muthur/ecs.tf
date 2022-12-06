locals {
  ecs_container_definition_muthur_server = [{
    image = var.muthur_docker_image
    name  = "muthur-server-${terraform.workspace}"

    linuxParameters = {
      initProcessEnabled = true  
    } 

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-create-group  = "true"
        awslogs-group         = "muthur-server-${terraform.workspace}"
        awslogs-region        = local.region
        awslogs-stream-prefix = "ecs-container"
      }
    }
    portMappings = [{
      hostPort      = local.muthur_port
      protocol      = "tcp"
      containerPort = local.muthur_port
    }]
   }]
   ecs_container_availability_zones_stringified = format("[%s]", join(", ", local.server_availability_zones))
}

resource "aws_security_group" "muthur_server" {
  name_prefix            = "muthur-server-sg-${terraform.workspace}"
  revoke_rules_on_delete = true
  tags                   = local.tags_rendered
  vpc_id                 = aws_vpc.muthur.id
}

resource "aws_security_group_rule" "allow_muthur_port_ingress" {
  from_port                = local.muthur_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.muthur_server.id
  source_security_group_id = aws_security_group.muthur_load_balancer.id
  to_port                  = local.muthur_port
  type                     = "ingress"
}

resource "aws_security_group_rule" "allow_outbound" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "tcp"
  security_group_id = aws_security_group.muthur_server.id
  to_port           = 65535
  type              = "egress"
}

resource "aws_ecs_cluster" "muthur_server" {
  name              = "muthur-server-${terraform.workspace}"
  tags               = local.tags_rendered
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "muthur_server" {
  cluster_name       = aws_ecs_cluster.muthur_server.name
  capacity_providers = ["FARGATE_SPOT"]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_ecs_service" "muthur_server" {
  cluster                           = aws_ecs_cluster.muthur_server.id
  desired_count                     = 1
  health_check_grace_period_seconds = 120
  launch_type                       = "FARGATE"
  name                              = "muthur-server-${terraform.workspace}"
  platform_version                  = "1.4.0"
  task_definition                   = aws_ecs_task_definition.muthur_server.arn
  enable_execute_command            = true
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      desired_count
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_muthur_server_https.arn
    container_name   = "muthur-server-${terraform.workspace}"
    container_port   = local.muthur_port
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.muthur_server.id]
    subnets          = local.subnet_public_ids
  }
}

resource "aws_ecs_task_definition" "muthur_server" {
  cpu                      = 128
  container_definitions    = jsonencode(local.ecs_container_definition_muthur_server)
  execution_role_arn       = aws_iam_role.muthur_server.arn
  family                   = "muthur-server-${terraform.workspace}"
  memory                   = 256
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  tags                     = local.tags_rendered
  task_role_arn            = aws_iam_role.muthur_server.arn
}
