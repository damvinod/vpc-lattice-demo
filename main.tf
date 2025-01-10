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
  docker_example        = "${local.team}-${local.environment}-docker-example"
  rds_name        = "${local.name}-rds"
  service_connect_example        = "${local.team}-${local.environment}-service-connect-example"

  tasks_iam_role_statements = {
    execute_allow = {
      actions = ["ecs:ExecuteCommand"]
      effect = "Allow"
      resources = [module.ecs.cluster_arn]
    }
  }
  task_exec_iam_statements = {
    create_log_group_for_service_connect = {
      actions = ["logs:CreateLogGroup"]
      effect = "Allow"
      resources = ["*"]
    }
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_availability_zones" "azs" {}

data "aws_ec2_managed_prefix_list" "vpc_lattice_prefix_list" {
  name = "com.amazonaws.${data.aws_region.current.name}.vpc-lattice"
}