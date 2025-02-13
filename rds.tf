module "aurora_mysql_v2" {
  count = var.enable_vpc_lattice_rds_resource_gw_demo ? 1 : 0

  source = "terraform-aws-modules/rds-aurora/aws"

  name              = local.rds_name
  engine            = "aurora-mysql"
  engine_mode       = "provisioned"
  engine_version    = "8.0"
  storage_encrypted = true
  master_username   = "root"

  vpc_id               = module.rds_vpc[0].vpc_id
  db_subnet_group_name = module.rds_vpc[0].database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      source_security_group_id = aws_security_group.resource_gateway_security_group[0].id
    }
  }

  apply_immediately   = true
  skip_final_snapshot = true

  serverlessv2_scaling_configuration = {
    min_capacity = 2
    max_capacity = 10
  }

  instance_class = "db.serverless"
  instances = {
    one = {}
  }

  tags = merge(local.tags, {
    Name = local.rds_name
  })
}

resource "aws_vpc_endpoint" "endpoint_to_rds_resource_gw" {
  count = var.enable_vpc_lattice_rds_resource_gw_demo ? 1 : 0

  vpc_endpoint_type          = "Resource"
  resource_configuration_arn = aws_vpclattice_resource_configuration.rds_resource_config[0].arn

  vpc_id     = module.demo_service_vpc.vpc_id
  subnet_ids = module.demo_service_vpc.private_subnets
  security_group_ids = [
    aws_security_group.endpoint_sg_for_resource_group[0].id
  ]

  tags = merge(local.tags, {
    Name = "${local.demo_svc}-endpoint-to-rds-resource-gw"
  })
}

resource "aws_security_group" "endpoint_sg_for_resource_group" {
  count = var.enable_vpc_lattice_rds_resource_gw_demo ? 1 : 0

  name   = "test-${local.name}"
  vpc_id = module.demo_service_vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.demo_service.security_group_id]
  }

  tags = merge(local.tags, {
    Name = "test-${local.name}"
  })
}