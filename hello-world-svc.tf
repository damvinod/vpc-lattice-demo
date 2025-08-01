resource "aws_ecs_service" "hello_world_svc" {
  count = var.enable_vpc_lattice_service_demo ? 1 : 0

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

  task_definition = module.hello_world[0].task_definition_arn

  network_configuration {
    assign_public_ip = true
    security_groups  = [module.hello_world[0].security_group_id]
    subnets          = module.hello_world_vpc[0].private_subnets
  }

  vpc_lattice_configurations {
    port_name        = "port-8080"
    role_arn         = aws_iam_role.ecs_infra_role[0].arn
    target_group_arn = aws_vpclattice_target_group.hello_world[0].arn
  }

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
  tags_all = merge(local.tags, {
    Name = local.hello_world_svc
  })
}

module "hello_world" {
  count = var.enable_vpc_lattice_service_demo ? 1 : 0

  source = "terraform-aws-modules/ecs/aws//modules/service"

  cpu    = 256
  memory = 512

  create_service = false
  name           = local.hello_world_svc
  cluster_arn    = module.ecs.cluster_arn

  assign_public_ip     = true
  autoscaling_policies = {}
  enable_autoscaling   = false
  desired_count        = 1

  enable_execute_command    = true
  tasks_iam_role_statements = local.tasks_iam_role_statements
  task_exec_iam_statements  = local.task_exec_iam_statements

  container_definitions = {
    hello_world_task = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "vinodreddy25/hello-world:master"
      portMappings = [
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
      readonlyRootFilesystem = false
    }
  }

  subnet_ids = module.hello_world_vpc[0].private_subnets

  security_group_ingress_rules = {
    ingress_port_8080 = {
      type            = "ingress"
      from_port       = 8080
      to_port         = 8080
      protocol        = "TCP"
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.vpc_lattice_prefix_list.id]
      description     = "Allow traffic on ingress 8080 for the VPC lattice to targets"
    }
  }

  security_group_egress_rules = {
    egress_all = {
      type      = "egress"
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_ipv4 = "0.0.0.0/0"
    }
  }

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
}

################
#VPC LATTICE
################
resource "aws_vpclattice_target_group" "hello_world" {
  count = var.enable_vpc_lattice_service_demo ? 1 : 0

  name = local.hello_world_svc
  type = "IP"

  config {
    vpc_identifier = module.hello_world_vpc[0].vpc_id

    ip_address_type = "IPV4"
    port            = 8080
    protocol        = "HTTP"

    health_check {
      enabled = true
      matcher {
        value = "404"
      }
      path     = "/"
      protocol = "HTTP"
    }
  }

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
}

resource "aws_vpclattice_listener_rule" "hello_world_get_hello_response" {
  count = var.enable_vpc_lattice_service_demo ? 1 : 0

  name                = local.hello_world_svc
  listener_identifier = aws_vpclattice_listener.hello_world[0].listener_id
  service_identifier  = aws_vpclattice_service.hello_world[0].id
  priority            = 1

  match {
    http_match {
      method = "GET"
      path_match {
        case_sensitive = true
        match {
          prefix = "/hello"
        }
      }
    }
  }

  action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.hello_world[0].id
        weight                  = 1
      }
    }
  }

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
}