resource "aws_vpclattice_target_group" "docker_example" {
  name = local.docker_example
  type = "IP"

  config {
    vpc_identifier = module.docker_example_vpc.vpc_id

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
    Name = local.docker_example
  })
}

resource "aws_vpclattice_service" "docker_example" {
  name      = local.docker_example
  auth_type = "NONE"

  tags = merge(local.tags, {
    Name = local.docker_example
  })
}

resource "aws_vpclattice_listener" "docker_example" {
  name               = local.docker_example
  protocol           = "HTTPS"
  service_identifier = aws_vpclattice_service.docker_example.id
  default_action {
    fixed_response {
      status_code = 404
    }
  }

  tags = merge(local.tags, {
    Name = local.docker_example
  })
}

resource "aws_vpclattice_listener_rule" "docker_example_get_hello_response" {
  name                = local.docker_example
  listener_identifier = aws_vpclattice_listener.docker_example.listener_id
  service_identifier  = aws_vpclattice_service.docker_example.id
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
        target_group_identifier = aws_vpclattice_target_group.docker_example.id
        weight                  = 1
      }
    }
  }

  tags = merge(local.tags, {
    Name = local.docker_example
  })
}

resource "aws_vpclattice_service_network" "docker_example" {
  name      = local.docker_example
  auth_type = "NONE"

  tags = merge(local.tags, {
    Name = local.docker_example
  })
}

resource "aws_vpclattice_service_network_service_association" "docker_example" {
  service_identifier         = aws_vpclattice_service.docker_example.id
  service_network_identifier = aws_vpclattice_service_network.docker_example.id

  tags = merge(local.tags, {
    Name = local.docker_example
  })
}

resource "aws_vpclattice_service_network_vpc_association" "demo_service_vpc_lattice_association" {
  vpc_identifier = module.demo_service_vpc.vpc_id
  service_network_identifier = aws_vpclattice_service_network.docker_example.id
  #security_group_ids         = [aws_security_group.example.id]

  tags = merge(local.tags, {
    Name = local.docker_example
  })
}