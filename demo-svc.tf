module "demo_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  cpu    = 256
  memory = 512

  name        = local.demo_svc
  cluster_arn = module.ecs.cluster_arn

  assign_public_ip     = true
  autoscaling_policies = {}
  enable_autoscaling   = false
  desired_count        = 1

  enable_execute_command    = true
  tasks_iam_role_statements = local.tasks_iam_role_statements
  task_exec_iam_statements  = local.task_exec_iam_statements

  service_connect_configuration = {
    enabled   = var.enable_service_connect_demo
    namespace = var.enable_service_connect_demo ? aws_service_discovery_private_dns_namespace.service_connect_namespace[0].name : null
  }

  container_definitions = {
    demo_service = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "vinodreddy25/demo-service:master"
      portMappings = [
        {
          name          = "port-8080"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = concat([
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "HELLO_WORLD_HOST_V1"
          value = "http://hello-world:8080"
        }
        ], var.enable_vpc_lattice_service_demo ? [
        {
          name  = "HELLO_WORLD_HOST"
          value = aws_vpclattice_service.hello_world[0].dns_entry[0].domain_name
        }
      ] : [])

      # Example image used requires access to write to root filesystem
      readonlyRootFilesystem = false
    }
  }

  subnet_ids = module.demo_service_vpc.private_subnets

  security_group_ingress_rules = {
    ingress_port_8080 = {
      type        = "ingress"
      from_port   = 8080
      to_port     = 8080
      protocol    = "TCP"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow traffic on ingress 8080"
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
    Name = local.demo_svc
  })
}