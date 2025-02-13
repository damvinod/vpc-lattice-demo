resource "aws_vpclattice_resource_gateway" "rds_resource_gateway" {
  count = var.enable_vpc_lattice_rds_resource_gw_demo ? 1 : 0

  name = "${local.rds_name}-gw"

  vpc_id             = module.rds_vpc[0].vpc_id
  subnet_ids         = module.rds_vpc[0].database_subnets
  security_group_ids = [aws_security_group.resource_gateway_security_group[0].id]

  tags = merge(local.tags, {
    Name = "${local.rds_name}-gw"
  })
}

resource "aws_vpclattice_resource_configuration" "rds_resource_config" {
  count = var.enable_vpc_lattice_rds_resource_gw_demo ? 1 : 0

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

resource "aws_security_group" "resource_gateway_security_group" {
  count = var.enable_vpc_lattice_rds_resource_gw_demo ? 1 : 0

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

resource "aws_vpclattice_access_log_subscription" "rds_resource_config_logs" {
  count = var.enable_vpc_lattice_rds_resource_gw_demo ? 1 : 0

  resource_identifier = aws_vpclattice_resource_configuration.rds_resource_config[0].id
  destination_arn     = aws_cloudwatch_log_group.resource_config_access_logs[0].arn
}

resource "aws_cloudwatch_log_group" "resource_config_access_logs" {
  count = var.enable_vpc_lattice_rds_resource_gw_demo ? 1 : 0

  name              = "${local.rds_name}/resource-config-access-logs"
  retention_in_days = 1

  tags = merge(local.tags, {
    Name = "${local.rds_name}/resource-config-access-logs"
  })
}