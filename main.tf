data "aws_iam_role" "ecs_task_exec_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecr_repository" "ac_ecr_repo" {
  name                 = "assetto-corsa"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_efs_file_system" "ac_efs_fs" {
  creation_token = "ac-server-01"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "ac-server-01"
  }
}

resource "aws_cloudwatch_log_group" "ac_log_group" {
  name              = "/aws/ecs/ac-server-01"
  retention_in_days = 7
}

module "ac_ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "ac-server-01"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ac_log_group.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "ac_task" {
  family                   = "ac_task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  task_role_arn            = data.aws_iam_role.ecs_task_exec_role.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_exec_role.arn
  container_definitions = jsonencode([
    {
      name             = "ac-server-01"
      image            = "989660949436.dkr.ecr.us-east-1.amazonaws.com/assetto-corsa:latest"
      cpu              = 2048
      memory           = 4096
      essential        = true
      taskRoleArn      = data.aws_iam_role.ecs_task_exec_role.arn
      executionRoleArn = data.aws_iam_role.ecs_task_exec_role.arn
      healthCheck = {
        command  = ["CMD-SHELL", "curl -f http://localhost:8081 || exit 1"]
        retries  = 5
        interval = 30
      }
      mountPoint = [
        {
          sourceVolume  = "server-install",
          containerPath = "/home/assetto/server-manager/assetto",
          readOnly      = false
        },
        {
          sourceVolume  = "config-file",
          containerPath = "/home/assetto/server-manager/config.yml",
          readOnly      = false
        }
      ]
      portMappings = [
        {
          containerPort = 8772
          hostPort      = 8772
        },
        {
          containerPort = 9600
          hostPort      = 9600
        },
        {
          containerPort = 9600
          hostPort      = 9600
          protocol      = "udp"
        },
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
    }
  ])

  volume {
    name = "server-install"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.ac_efs_fs.id
      root_directory = "/server-install"
    }
  }

  volume {
    name = "config-file"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.ac_efs_fs.id
      root_directory = "/config.yml"
    }
  }
}
