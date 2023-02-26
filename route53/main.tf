resource "aws_route53_record" "apigw_record" {
  zone_id = var.route53_zone_id
  name    = "apis.${terraform.workspace}.gamma.com"
  type    = "CNAME"
  ttl     = 300
  records = [var.gamma_lb_dns]
}

resource "aws_route53_record" "users_api_record" {
  zone_id = var.route53_zone_id
  name    = "useraccounts-api.${terraform.workspace}.gamma.com"
  type    = "CNAME"
  ttl     = 300
  records = [var.gamma_lb_dns]
}

resource "aws_route53_record" "gamenegine_api_record" {
  zone_id = var.route53_zone_id
  name    = "gameengine-api.${terraform.workspace}.gamma.com"
  type    = "CNAME"
  ttl     = 300
  records = [var.gamma_lb_dns]
}