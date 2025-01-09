resource "aws_ecs_service" "docker_example_service" {
  name    = local.docker_example
  cluster = module.ecs.cluster_arn

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 66
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  enable_execute_command             = true
  force_new_deployment               = true
  health_check_grace_period_seconds  = 0
  launch_type                        = "FARGATE"
  propagate_tags                     = "NONE"

  task_definition = module.docker_example.task_definition_arn

  network_configuration {
    assign_public_ip = true
    security_groups = [module.docker_example.security_group_id]
    subnets          = module.docker_example_vpc.private_subnets
  }

  vpc_lattice_configurations {
    port_name        = "port-8080"
    role_arn         = aws_iam_role.ecs_infra_role.arn
    target_group_arn = aws_vpclattice_target_group.docker_example.arn
  }

  tags = merge(local.tags, {
    Name = local.docker_example
  })
  tags_all = merge(local.tags, {
    Name = local.docker_example
  })
}

module "docker_example" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  cpu    = 256
  memory = 512

  create_service = false
  name           = local.docker_example
  cluster_arn    = module.ecs.cluster_arn

  assign_public_ip       = true
  enable_execute_command = true
  create_tasks_iam_role  = false
  tasks_iam_role_arn     = aws_iam_role.docker_example.arn
  autoscaling_policies = {}
  desired_count          = 1

  task_exec_iam_role_policies = { (aws_iam_policy.docker_example_task_execute.name) : aws_iam_policy.docker_example_task_execute.arn }

  container_definitions = {
    docker-example = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "vinodreddy25/docker-example:master"
      port_mappings = [
        {
          name          = "port-8080"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false
    }
  }

  subnet_ids = module.docker_example_vpc.private_subnets

  security_group_rules = {
    ingress_port_8080 = {
      type        = "ingress"
      from_port   = 8080
      to_port     = 8080
      protocol    = "TCP"
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.vpc_lattice_prefix_list.id]
      description = "Allow traffic on ingress 8080 for the VPC lattice to targets"
    }
    egress_all = {
      type      = "egress"
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(local.tags, {
    Name = local.docker_example
  })
}

resource "aws_iam_role" "docker_example" {

  name_prefix = "${local.docker_example}-"

  assume_role_policy    = data.aws_iam_policy_document.docker_example_assume_policy.json
  force_detach_policies = true

  tags = local.tags
}

data "aws_iam_policy_document" "docker_example_assume_policy" {

  statement {
    sid = "ECSTasksAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#create_task_iam_policy_and_role
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "docker_example" {
  version = "2012-10-17"
  statement {
    actions = ["ecs:ExecuteCommand"]
    effect = "Allow"
    resources = [module.ecs.cluster_arn]
  }
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    effect = "Allow"
    resources = ["*"]
  }
  statement {
    actions = ["logs:CreateLogGroup"]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "docker_example" {
  name        = local.docker_example
  description = "Policy to allow execute command."
  policy      = data.aws_iam_policy_document.docker_example.json
}

resource "aws_iam_role_policy_attachment" "docker_example" {
  role       = aws_iam_role.docker_example.name
  policy_arn = aws_iam_policy.docker_example.arn
}

data "aws_iam_policy_document" "docker_example_task_execute" {
  version = "2012-10-17"
  statement {
    actions = ["logs:CreateLogGroup"]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "docker_example_task_execute" {
  name        = "${local.docker_example}-task-exec"
  description = "Policy to allow access to create log group."
  policy      = data.aws_iam_policy_document.docker_example_task_execute.json
}