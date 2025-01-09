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
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_availability_zones" "azs" {}

data "aws_ec2_managed_prefix_list" "vpc_lattice_prefix_list" {
  name = "com.amazonaws.${data.aws_region.current.name}.vpc-lattice"
}