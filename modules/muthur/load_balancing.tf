resource "aws_security_group" "muthur_load_balancer" {
  name_prefix            = "muthur-lb-sg-${terraform.workspace}"
  revoke_rules_on_delete = true
  tags                   = local.tags_rendered
  vpc_id                 = aws_vpc.muthur.id

  depends_on = [aws_internet_gateway.muthur]
}

resource "aws_security_group_rule" "lb_allow_inbound_443" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.muthur_load_balancer.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "lb_allow_muthur_port_egress" {
  from_port                = local.muthur_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.muthur_load_balancer.id
  source_security_group_id = aws_security_group.muthur_server.id
  to_port                  = local.muthur_port
  type                     = "egress"
}

resource "aws_lb" "muthur_server" {
  name               = "muthur-server-${terraform.workspace}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.muthur_load_balancer.id]
  subnets            = local.subnet_public_ids
  tags               = local.tags_rendered
}

resource "aws_lb_target_group" "lb_muthur_server_https" {
  name        = "${aws_lb.muthur_server.name}-https-tg"
  port        = local.muthur_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.muthur.id

  health_check {
    healthy_threshold = 2
    matcher           = "200-299,302"
    path              = "/"
    protocol          = "HTTP"
  }
}

resource "aws_lb_listener" "muthur_server_https" {
  load_balancer_arn = aws_lb.muthur_server.arn
  port              = aws_security_group_rule.lb_allow_inbound_443.from_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_muthur_server_https.arn
  }
}

output lb_arn {
  description = "The ARN of the application load balancer in front of the Fargate task serving the muthur container."
  value       = aws_lb.muthur_server.arn
}

output lb_dns_name {
  description = "The main entrypoint to the muthur tool for users and GMs. Is the DNS name of the application load balancer in front of the Fargate task serving the muthur container. Can be used with Route53."
  value       = aws_lb.muthur_server.dns_name
}

output lb_zone_id {
  description = "The Route53 zone ID of the application load balancer in front of the Fargate task serving the muthur container."
  value       = aws_lb.muthur_server.zone_id
}

output target_group_https_arn {
  description = "The ARN of the HTTPS target group receiving traffic from the HTTPS ALB listener."
  value       = aws_lb_target_group.lb_muthur_server_https.arn
}

output target_group_https_name {
  description = "The name of the HTTPS target group receiving traffic from the HTTPS ALB listener."
  value       = aws_lb_target_group.lb_muthur_server_https.name
}
