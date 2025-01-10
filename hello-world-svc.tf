resource "aws_ecs_service" "hello_world_svc" {
  name    = local.hello_world_svc
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

  task_definition = module.hello_world.task_definition_arn

  network_configuration {
    assign_public_ip = true
    security_groups = [module.hello_world.security_group_id]
    subnets          = module.hello_world_vpc.private_subnets
  }

  vpc_lattice_configurations {
    port_name        = "port-8080"
    role_arn         = aws_iam_role.ecs_infra_role.arn
    target_group_arn = aws_vpclattice_target_group.hello_world.arn
  }

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
  tags_all = merge(local.tags, {
    Name = local.hello_world_svc
  })
}

module "hello_world" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  cpu    = 256
  memory = 512

  create_service = false
  name           = local.hello_world_svc
  cluster_arn    = module.ecs.cluster_arn

  assign_public_ip       = true
  autoscaling_policies = {}
  desired_count          = 1

  enable_execute_command = true
  tasks_iam_role_statements = local.tasks_iam_role_statements
  task_exec_iam_statements = local.task_exec_iam_statements

  container_definitions = {
    hello_world_task = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "vinodreddy25/hello-world:master"
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

  subnet_ids = module.hello_world_vpc.private_subnets

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
    Name = local.hello_world_svc
  })
}