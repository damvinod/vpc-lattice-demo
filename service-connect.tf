module "service_connect_demo" {
  count = var.enable_service_connect_demo ? 1 : 0

  source = "terraform-aws-modules/ecs/aws//modules/service"

  cpu    = 256
  memory = 512

  name        = local.service_connect_example
  cluster_arn = module.ecs.cluster_arn

  assign_public_ip = true
  autoscaling_policies = {}
  desired_count    = 1

  enable_execute_command    = true
  tasks_iam_role_statements = local.tasks_iam_role_statements
  task_exec_iam_statements  = local.task_exec_iam_statements

  service_connect_configuration = {
    enabled   = true
    # log_configuration = {
    #
    # }
    namespace = aws_service_discovery_http_namespace.service_connect_namespace[0].name
    service = {
      client_alias = {
        dns_name = "docker-example"
        port     = 8080
      }
      discovery_name = "docker-example"
      port_name      = "port-8080"
    }
  }

  container_definitions = {
    service_connect_demo = {
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

  subnet_ids = module.demo_service_vpc.private_subnets

  security_group_rules = {
    ingress_port_8080 = {
      type                     = "ingress"
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "TCP"
      source_security_group_id = module.demo_service.security_group_id
      description              = "Allow traffic on ingress 8080 from demo service."
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
    Name = local.service_connect_example
  })
}

resource "aws_service_discovery_http_namespace" "service_connect_namespace" {
  count = var.enable_service_connect_demo ? 1 : 0

  name = local.service_connect_example

  tags = merge(local.tags, {
    Name = local.service_connect_example
  })
}