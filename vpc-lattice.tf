resource "aws_vpclattice_target_group" "hello_world" {
  name = local.hello_world_svc
  type = "IP"

  config {
    vpc_identifier = module.hello_world_vpc.vpc_id

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

resource "aws_vpclattice_listener_rule" "hello_world_get_hello_response" {
  name                = local.hello_world_svc
  listener_identifier = aws_vpclattice_listener.hello_world.listener_id
  service_identifier  = aws_vpclattice_service.hello_world.id
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
        target_group_identifier = aws_vpclattice_target_group.hello_world.id
        weight                  = 1
      }
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
  vpc_identifier = module.demo_service_vpc.vpc_id
  service_network_identifier = aws_vpclattice_service_network.hello_world.id
  #security_group_ids         = [aws_security_group.example.id]

  tags = merge(local.tags, {
    Name = local.hello_world_svc
  })
}