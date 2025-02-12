resource "aws_vpclattice_service" "hello_world" {
  name      = local.hello_world_svc
  auth_type = "NONE"

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
}

resource "aws_vpclattice_listener" "hello_world" {
  name               = local.hello_world_svc
  protocol           = "HTTPS"
  service_identifier = aws_vpclattice_service.hello_world.id
  default_action {
    fixed_response {
      status_code = 404
    }
  }

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
}

resource "aws_vpclattice_service_network" "hello_world" {
  name      = local.hello_world_svc
  auth_type = "NONE"

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
}

resource "aws_vpclattice_service_network_service_association" "hello_world" {
  service_identifier         = aws_vpclattice_service.hello_world.id
  service_network_identifier = aws_vpclattice_service_network.hello_world.id

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
}

resource "aws_vpclattice_service_network_vpc_association" "demo_service_vpc_lattice_association" {
  vpc_identifier             = module.demo_service_vpc.vpc_id
  service_network_identifier = aws_vpclattice_service_network.hello_world.id
  #security_group_ids         = [aws_security_group.example.id]

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
}