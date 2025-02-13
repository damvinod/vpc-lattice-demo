module "aurora_mysql_v2" {
  count = var.enable_vpc_lattice_rds_resource_gw ? 1 : 0

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

resource "aws_security_group" "resource_gateway_security_group" {
  count = var.enable_vpc_lattice_rds_resource_gw ? 1 : 0

  name   = "${local.rds_name}-resource-gw-sg"
  vpc_id = module.rds_vpc[0].vpc_id

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = module.rds_vpc[0].database_subnets_cidr_blocks
  }

  tags = merge(local.tags, {
    Name = "${local.rds_name}-resource-gw-sg"
  })
}

resource "aws_vpclattice_resource_gateway" "rds_resource_gateway" {
  count = var.enable_vpc_lattice_rds_resource_gw ? 1 : 0

  name = "${local.rds_name}-gw"

  vpc_id     = module.rds_vpc[0].vpc_id
  subnet_ids = module.rds_vpc[0].database_subnets
  security_group_ids = [aws_security_group.resource_gateway_security_group[0].id]

  tags = merge(local.tags, {
    Name = "${local.rds_name}-gw"
  })
}

resource "aws_vpclattice_resource_configuration" "rds_resource_config" {
  count = var.enable_vpc_lattice_rds_resource_gw ? 1 : 0

  name = "${local.rds_name}-config"
  type = "ARN"

  resource_gateway_identifier = aws_vpclattice_resource_gateway.rds_resource_gateway[0].id

  resource_configuration_definition {
    arn_resource {
      arn = module.aurora_mysql_v2[0].cluster_arn
    }
  }

  tags = merge(local.tags, {
    Name = "${local.rds_name}-config"
  })
}

resource "aws_vpclattice_access_log_subscription" "rds_resource_config_logs" {
  count = var.enable_vpc_lattice_rds_resource_gw ? 1 : 0

  resource_identifier = aws_vpclattice_resource_configuration.rds_resource_config[0].id
  destination_arn     = aws_cloudwatch_log_group.resource_config_access_logs[0].arn
}

resource "aws_cloudwatch_log_group" "resource_config_access_logs" {
  count = var.enable_vpc_lattice_rds_resource_gw ? 1 : 0

  name              = "${local.rds_name}/resource-config-access-logs"
  retention_in_days = 1

  tags = merge(local.tags, {
    Name = "${local.rds_name}/resource-config-access-logs"
  })
}

resource "aws_vpc_endpoint" "endpoint_to_rds_resource_gw" {
  count = var.enable_vpc_lattice_rds_resource_gw ? 1 : 0

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
  count = var.enable_vpc_lattice_rds_resource_gw ? 1 : 0

  name   = "test-${local.name}"
  vpc_id = module.demo_service_vpc.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [module.demo_service.security_group_id]
  }

  tags = merge(local.tags, {
    Name = "test-${local.name}"
  })
}