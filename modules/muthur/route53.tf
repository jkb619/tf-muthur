resource "aws_route53_record" "cloud-muthur" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.muthur_server.dns_name
    zone_id                = aws_lb.muthur_server.zone_id
    evaluate_target_health = true
  }
}
