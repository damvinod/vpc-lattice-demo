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

  default_capacity_provider_strategy = {
    FARGATE_SPOT = {
      weight = 100
    }
  }

  tags = merge(local.tags, {
    Name = local.name
  })
}

resource "aws_iam_role" "ecs_infra_role" {
  count = var.enable_vpc_lattice_service_demo ? 1 : 0

  name_prefix = "${local.name}-infra-"

  assume_role_policy    = data.aws_iam_policy_document.ecs_infra_role_assume_policy[0].json
  force_detach_policies = true

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_infra_role_attachment" {
  count = var.enable_vpc_lattice_service_demo ? 1 : 0

  role       = aws_iam_role.ecs_infra_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForVpcLattice"
}

data "aws_iam_policy_document" "ecs_infra_role_assume_policy" {
  count = var.enable_vpc_lattice_service_demo ? 1 : 0

  statement {
    sid     = "AllowAccessToECSForInfrastructureManagement"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}