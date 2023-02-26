resource "aws_lb" "gamma_lb" {
  name               = "gamma-${terraform.workspace}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.gamma_lb_sg
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "gamma-${terraform.workspace}-lb"
  }
}

resource "aws_lb_listener" "gamma_lb_listener" {
  load_balancer_arn = aws_lb.gamma_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.apigw_cert_validation.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gamma_api_tg.arn
  }
}

resource "aws_lb_listener" "redirect" {
  load_balancer_arn = aws_lb.gamma_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      port        = 443
      protocol    = "HTTPS"
    }
  }
}


resource "aws_lb_target_group" "gamma_api_tg" {
  name = "gamma-${terraform.workspace}-api-tg"
  port = 80

  protocol    = "HTTP"
  vpc_id      = var.gamma_vpc_id
  target_type = "ip"
  lifecycle {
    create_before_destroy = false
    ignore_changes        = [name]
  }
  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    interval            = var.elb_interval
    path                = "/health"
  }
}

resource "aws_lb_listener_rule" "apigw_listener" {
  listener_arn = aws_lb_listener.gamma_lb_listener.arn
  priority     = 4
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gamma_api_tg.arn
  }

  condition {
    host_header {
      values = ["apis.${terraform.workspace}.gamma.com"]
    }
  }
}






resource "aws_lb_target_group" "gamma_game_engine_tg" {
  name        = "gamma-${terraform.workspace}-game-engine-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.gamma_vpc_id
  target_type = "ip"
  lifecycle {
    create_before_destroy = false
    ignore_changes        = [name]
  }
  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    interval            = var.elb_interval
    path                = "/api/health"
  }
}

resource "aws_lb_listener_rule" "game_engine_listener" {
  listener_arn = aws_lb_listener.gamma_lb_listener.arn
  priority     = 2
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gamma_game_engine_tg.arn
  }

  condition {
    host_header {
      values = ["gameengine-api.${terraform.workspace}.gamma.com"]
    }
  }
}


resource "aws_lb_target_group" "gamma_users_tg" {
  name        = "gamma-${terraform.workspace}-users-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.gamma_vpc_id
  target_type = "ip"
  lifecycle {
    create_before_destroy = false
    ignore_changes        = [name]
  }
  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    interval            = var.elb_interval
    path                = "/api/health"
  }
}

resource "aws_lb_listener_rule" "users_api_listener" {
  listener_arn = aws_lb_listener.gamma_lb_listener.arn
  priority     = 3
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gamma_users_tg.arn
  }

  condition {
    host_header {
      values = ["useraccounts-api.${terraform.workspace}.gamma.com"]
    }
  }
}

resource "aws_lb_listener_certificate" "frontend" {
  listener_arn    = aws_lb_listener.gamma_lb_listener.arn
  certificate_arn = aws_acm_certificate_validation.game_engine_cert_validation.certificate_arn
}
resource "aws_lb_listener_certificate" "backend" {
  listener_arn    = aws_lb_listener.gamma_lb_listener.arn
  certificate_arn = aws_acm_certificate_validation.users_api_cert_validation.certificate_arn
}
resource "aws_lb_listener_certificate" "admin" {
  listener_arn    = aws_lb_listener.gamma_lb_listener.arn
  certificate_arn = aws_acm_certificate_validation.apigw_cert_validation.certificate_arn
}


resource "aws_acm_certificate" "users_api_cert" {
  domain_name       = "useraccounts-api.${terraform.workspace}.gamma.com"
  validation_method = "DNS"

  tags = {
    Environment = "${terraform.workspace}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "users_api_cert_val" {
  for_each = {
    for dvo in aws_acm_certificate.users_api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "users_api_cert_validation" {
  certificate_arn         = aws_acm_certificate.users_api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.users_api_cert_val : record.fqdn]
}


resource "aws_acm_certificate" "game_engine_api_cert" {
  domain_name       = "gameengine-api.${terraform.workspace}.gamma.com"
  validation_method = "DNS"

  tags = {
    Environment = "${terraform.workspace}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "game_engine_api_cert_val" {
  for_each = {
    for dvo in aws_acm_certificate.game_engine_api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "game_engine_cert_validation" {
  certificate_arn         = aws_acm_certificate.game_engine_api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.game_engine_api_cert_val : record.fqdn]
}


resource "aws_acm_certificate" "apigw_cert" {
  domain_name       = "apis.${terraform.workspace}.gamma.com"
  validation_method = "DNS"

  tags = {
    Environment = "${terraform.workspace}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "apigw_cert_val" {
  for_each = {
    for dvo in aws_acm_certificate.apigw_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "apigw_cert_validation" {
  certificate_arn         = aws_acm_certificate.apigw_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.apigw_cert_val : record.fqdn]
}
