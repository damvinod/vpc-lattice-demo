module "demo_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  cpu    = 256
  memory = 512

  name        = "${local.name}-service"
  cluster_arn = module.ecs.cluster_arn

  assign_public_ip = true
  autoscaling_policies = {}
  desired_count    = 1

  enable_execute_command = true
  tasks_iam_role_statements = local.tasks_iam_role_statements
  task_exec_iam_statements = local.task_exec_iam_statements

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
      type      = "egress"
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name}-service"
  })
}