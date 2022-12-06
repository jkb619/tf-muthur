module "muthur_server" {
  source = "./modules/muthur"

  aws_account_id          = var.aws_account_id
  domain_name             = var.domain_name
  ssl_certificate_arn     = var.ssl_certificate_arn
  route53_zone_id         = var.route53_zone_id
}

provider "aws" {
  region = "us-east-2"
}

output endpoint {
  value = module.muthur_server.lb_dns_name
}
