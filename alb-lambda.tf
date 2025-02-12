module "alb_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.alb_hello_world

  handler = "lambda_function.lambda_handler"
  runtime = "python3.13"

  source_path = "${path.module}/lambda/lambda_function.py"

  publish = true
  allowed_triggers = {
    OneRule = {
      principal  = "elasticloadbalancing.amazonaws.com"
      source_arn = aws_lb_target_group.lambda_target_group.arn
    }
  }

  tags = {
    Name = local.alb_hello_world
  }
}

resource "aws_lb" "load_balancer" {
  name               = local.alb_hello_world
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_lambda_security_group.id]
  subnets            = module.hello_world_vpc.private_subnets
  tags = {
    Name = local.alb_hello_world
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda_target_group.arn
  }
}

resource "aws_lb_target_group" "lambda_target_group" {
  name        = local.alb_hello_world
  target_type = "lambda"
  vpc_id      = module.hello_world_vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "lambda_target_group_attachment" {
  target_group_arn = aws_lb_target_group.lambda_target_group.arn
  target_id        = module.alb_lambda_function.lambda_function_arn

  depends_on = [aws_lb_listener.listener]
}

resource "aws_security_group" "alb_lambda_security_group" {
  name = "${local.alb_hello_world}-sg"

  vpc_id = module.hello_world_vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.vpc_lattice_prefix_list.id]
  }

  tags = merge(local.tags, {
    Name = "${local.alb_hello_world}-sg"
  })
}

#####################
#VPC LATTICE FOR ALB
#####################
resource "aws_vpclattice_target_group" "alb_lambda" {
  name = local.alb_hello_world
  type = "ALB"

  config {
    vpc_identifier = module.hello_world_vpc.vpc_id

    port     = 80
    protocol = "HTTP"
  }

  tags = merge(local.tags, {
    Name = local.alb_hello_world
  })
}

resource "aws_vpclattice_target_group_attachment" "alb_lambda" {
  target_group_identifier = aws_vpclattice_target_group.alb_lambda.id

  target {
    id   = aws_lb.load_balancer.arn
    port = 80
  }
}

resource "aws_vpclattice_listener_rule" "alb_lambda_response" {
  name                = local.alb_hello_world
  listener_identifier = aws_vpclattice_listener.hello_world.listener_id
  service_identifier  = aws_vpclattice_service.hello_world.id
  priority            = 2

  match {
    http_match {
      method = "GET"
      path_match {
        case_sensitive = true
        match {
          prefix = "/alb"
        }
      }
    }
  }

  action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.alb_lambda.id
        weight                  = 1
      }
    }
  }

  tags = merge(local.tags, {
    Name = local.alb_hello_world
  })
}

########################
#VPC LATTICE FOR LAMBDA
########################
resource "aws_vpclattice_target_group" "lambda" {
  name = local.lambda_hello_world
  type = "LAMBDA"

  config {
    lambda_event_structure_version = "V2"
  }

  tags = merge(local.tags, {
    Name = local.lambda_hello_world
  })
}

resource "aws_vpclattice_target_group_attachment" "lambda" {
  target_group_identifier = aws_vpclattice_target_group.lambda.id

  target {
    id   = module.alb_lambda_function.lambda_function_arn_static
    port = 80
  }
}

resource "aws_vpclattice_listener_rule" "lambda_response" {
  name                = local.lambda_hello_world
  listener_identifier = aws_vpclattice_listener.hello_world.listener_id
  service_identifier  = aws_vpclattice_service.hello_world.id
  priority            = 3

  match {
    http_match {
      method = "GET"
      path_match {
        case_sensitive = true
        match {
          prefix = "/lambda"
        }
      }
    }
  }

  action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.lambda.id
        weight                  = 1
      }
    }
  }

  tags = merge(local.tags, {
    Name = local.lambda_hello_world
  })
}