resource "aws_lb" "frontend" {
  name                              = "roboshop-public-lb-${var.ENV}"
  internal                          = false
  load_balancer_type                = "application"
  security_groups                   = [aws_security_group.allow_web_public.id]
  subnets                           = data.terraform_remote_state.vpc.outputs.PUBLIC_SUBNETS

  tags                              = {
    Environment                     = "roboshop-public-lb-${var.ENV}"
  }
}

resource "aws_route53_record" "frontend-alb" {
  name                              = "roboshop-${var.ENV}"
  type                              = "CNAME"
  zone_id                           = data.terraform_remote_state.vpc.outputs.EXTERNAL_DOMAIN_ID
  ttl                               = "300"
  records                           = [aws_lb.frontend.dns_name]
}

resource "aws_lb_listener" "front_end-https" {
  load_balancer_arn                 = aws_lb.frontend.arn
  port                              = "443"
  protocol                          = "HTTPS"
  ssl_policy                        = "ELBSecurityPolicy-2016-08"
  certificate_arn                   = var.CERT_ARN

  default_action {
    type                            = "forward"
    target_group_arn                = module.asg.TG_ARN
  }
}

resource "aws_lb_listener" "front_end-http" {
  load_balancer_arn                 = aws_lb.frontend.arn
  port                              = "80"
  protocol                          = "HTTP"

  default_action {
    type                            = "redirect"

    redirect {
      port                          = "443"
      protocol                      = "HTTPS"
      status_code                   = "HTTP_301"
    }
  }
}

resource "aws_security_group" "allow_web_public" {
  name                              = "allow_web_public"
  description                       = "allow_web_public"
  vpc_id                            = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description                     = "HTTP PUBLIC"
    from_port                       = 80
    to_port                         = 80
    protocol                        = "tcp"
    cidr_blocks                     = ["0.0.0.0/0"]
  }

  ingress {
    description                     = "HTTPS PUBLIC"
    from_port                       = 443
    to_port                         = 443
    protocol                        = "tcp"
    cidr_blocks                     = ["0.0.0.0/0"]
  }

  egress {
    from_port                       = 0
    to_port                         = 0
    protocol                        = "-1"
    cidr_blocks                     = ["0.0.0.0/0"]
  }

  tags                              = {
    Name                            = "allow_web_public"
  }
}


// Backend Load Balancer

resource "aws_lb" "backend" {
  name                              = "roboshop-backend-lb-${var.ENV}"
  internal                          = true
  load_balancer_type                = "application"
  security_groups                   = [aws_security_group.allow_web_internal.id]
  subnets                           = data.terraform_remote_state.vpc.outputs.WEB_SUBNETS

  tags                              = {
    Environment                     = "roboshop-public-lb-${var.ENV}"
  }
}

resource "aws_security_group" "allow_web_internal" {
  name                              = "allow_web_internal"
  description                       = "allow_web_internal"
  vpc_id                            = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description                     = "HTTP PUBLIC"
    from_port                       = 80
    to_port                         = 80
    protocol                        = "tcp"
    cidr_blocks                     = [data.terraform_remote_state.vpc.outputs.VPC_CIDR]
  }

  egress {
    from_port                       = 0
    to_port                         = 0
    protocol                        = "-1"
    cidr_blocks                     = ["0.0.0.0/0"]
  }

  tags                              = {
    Name                            = "allow_web_internal"
  }
}

resource "aws_route53_record" "backend-alb" {
  count                             = length(var.COMPONENTS)
  name                              = "${element(var.COMPONENTS, count.index)}-${var.ENV}"
  type                              = "CNAME"
  zone_id                           = data.terraform_remote_state.vpc.outputs.INTERNAL_DOMAIN_ID
  ttl                               = "300"
  records                           = [aws_lb.backend.dns_name]
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn                 = aws_lb.backend.arn
  port                              = "80"
  protocol                          = "HTTP"

  default_action {
    type                            = "fixed-response"

    fixed_response {
      content_type                  = "text/plain"
      message_body                  = "Ok"
      status_code                   = "200"
    }
  }
}
