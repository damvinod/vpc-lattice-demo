module "demo_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"

  cpu    = 256
  memory = 512

  name        = "${local.name}-service"
  cluster_arn = module.ecs.cluster_arn

  assign_public_ip       = true
  enable_execute_command = true
  create_tasks_iam_role  = false
  tasks_iam_role_arn     = aws_iam_role.demo_service.arn
  autoscaling_policies   = {}
  desired_count          = 1

  task_exec_iam_role_policies = { (aws_iam_policy.demo_service_task_execute.name) : aws_iam_policy.demo_service_task_execute.arn }

  container_definitions = {
    demo-service = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "vinodreddy25/demo-service:master"
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
        },
        {
          name  = "DOCKER_EXAMPLE_HOST"
          value = "http://docker-example:8080"
        }
      ]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false
    }
  }

  subnet_ids = module.demo_service_vpc.private_subnets

  security_group_rules = {
    ingress_port_8080 = {
      type        = "ingress"
      from_port   = 8080
      to_port     = 8080
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow traffic on ingress 8080"
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name}-service"
  })
}

resource "aws_iam_role" "demo_service" {

  name_prefix = "${local.name}-service-"

  assume_role_policy    = data.aws_iam_policy_document.demo_service_assume_policy.json
  force_detach_policies = true

  tags = local.tags
}

data "aws_iam_policy_document" "demo_service_assume_policy" {

  statement {
    sid     = "ECSTasksAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#create_task_iam_policy_and_role
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "demo_service" {
  version = "2012-10-17"
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"]
  }
  statement {
    actions   = ["ecs:ExecuteCommand"]
    effect    = "Allow"
    resources = [module.ecs.cluster_arn]
  }
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = ["logs:CreateLogGroup"]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "demo_service" {
  name        = local.name
  description = "Policy to allow reading secrets from SecretsManager and allow execute command."
  policy      = data.aws_iam_policy_document.demo_service.json
}

resource "aws_iam_role_policy_attachment" "demo_service" {
  role       = aws_iam_role.demo_service.name
  policy_arn = aws_iam_policy.demo_service.arn
}

data "aws_iam_policy_document" "demo_service_task_execute" {
  version = "2012-10-17"
  statement {
    actions = ["logs:CreateLogGroup"]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "demo_service_task_execute" {
  name        = "${local.name}-task-exec"
  description = "Policy to allow access to create log group."
  policy      = data.aws_iam_policy_document.demo_service_task_execute.json
}