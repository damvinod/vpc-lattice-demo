module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = local.name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  tags = merge(local.tags, {
    Name = local.name
  })
}

resource "aws_iam_role" "ecs_infra_role" {

  name_prefix = "${local.name}-infra-"

  assume_role_policy    = data.aws_iam_policy_document.ecs_infra_role_assume_policy.json
  force_detach_policies = true
  managed_policy_arns   = ["arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForVpcLattice"]

  tags = local.tags
}

data "aws_iam_policy_document" "ecs_infra_role_assume_policy" {

  statement {
    sid     = "AllowAccessToECSForInfrastructureManagement"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}