locals {
  team        = var.team_name
  stack       = "vpc-lattice-demo"
  environment = var.environment
  name        = "${local.team}-${local.environment}-${local.stack}"
  tags = {
    team        = local.team
    stack       = local.stack
    environment = local.environment
  }

  hello_world_svc    = "${local.team}-${local.environment}-hello-world-svc"
  demo_svc           = "${local.team}-${local.environment}-demo-svc"
  hello_world_v1_svc = "${local.team}-${local.environment}-hello-world-v1-svc"
  alb_hello_world    = "${local.team}-${local.environment}-hello-world-alb"
  lambda_hello_world = "${local.team}-${local.environment}-hello-world-lambda"

  tasks_iam_role_statements = {
    execute_allow = {
      actions   = ["ecs:ExecuteCommand"]
      effect    = "Allow"
      resources = [module.ecs.cluster_arn]
    }
  }
  task_exec_iam_statements = {
    create_log_group_for_service_connect = {
      actions   = ["logs:CreateLogGroup"]
      effect    = "Allow"
      resources = ["*"]
    }
  }

  rds_name = "${local.name}-rds"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_availability_zones" "azs" {}

data "aws_ec2_managed_prefix_list" "vpc_lattice_prefix_list" {
  name = "com.amazonaws.${data.aws_region.current.name}.vpc-lattice"
}