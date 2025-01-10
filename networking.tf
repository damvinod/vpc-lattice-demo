module "demo_service_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.demo_svc
  cidr = "10.0.0.0/16"
  tags = merge(local.tags, {
    Name = local.demo_svc
  })

  azs = data.aws_availability_zones.azs.names

  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnet_tags = merge(local.tags, {
    Name = "${local.demo_svc}-public"
    type = "public"
  })
  public_route_table_tags = merge(local.tags, {
    Name = "${local.demo_svc}-public"
    type = "public"
  })

  private_subnets = [
    # Private subnets
    "10.0.108.0/23", "10.0.110.0/23", "10.0.112.0/23",
  ]
  private_subnet_tags = merge(local.tags, {
    Name = "${local.demo_svc}-private"
    type = "private"
  })
  private_route_table_tags = merge(local.tags, {
    Name = "${local.demo_svc}-private"
    type = "private"
  })

  enable_dns_hostnames = true

  # One NAT per Az
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}

module "hello_world_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.hello_world_svc
  cidr = "172.16.0.0/16"
  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })

  azs = data.aws_availability_zones.azs.names

  public_subnets = ["172.16.101.0/24", "172.16.102.0/24", "172.16.103.0/24"]
  public_subnet_tags = merge(local.tags, {
    Name = "${local.hello_world_svc}-public"
    type = "public"
  })
  public_route_table_tags = merge(local.tags, {
    Name = "${local.hello_world_svc}-public"
    type = "public"
  })

  private_subnets = [
    # Private subnets
    "172.16.108.0/23", "172.16.110.0/23", "172.16.112.0/23",
  ]
  private_subnet_tags = merge(local.tags, {
    Name = "${local.hello_world_svc}-private"
    type = "private"
  })
  private_route_table_tags = merge(local.tags, {
    Name = "${local.hello_world_svc}-private"
    type = "private"
  })

  enable_dns_hostnames = true

  # One NAT per Az
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}

module "rds_vpc" {
  count  = var.create_rds ? 1 : 0
  source = "terraform-aws-modules/vpc/aws"

  name = local.rds_name
  cidr = "172.17.0.0/16"
  tags = merge(local.tags, {
    Name = local.rds_name
  })

  azs = data.aws_availability_zones.azs.names

  create_database_subnet_route_table = true
  database_subnets = [
    # Private subnets
    "172.17.108.0/23", "172.17.110.0/23", "172.17.112.0/23",
  ]
  database_subnet_tags = merge(local.tags, {
    Name = local.rds_name
    type = "db"
  })
  database_route_table_tags = merge(local.tags, {
    Name = local.rds_name
    type = "db"
  })

  enable_dns_hostnames = true
}