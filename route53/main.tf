resource "aws_route53_record" "apigw_record" {
  zone_id = "Z0959434624C4DPQXHIJ"
  name    = "apis.beta.gamma.com"
  type    = "CNAME"
  ttl     = 300
  records = [var.gamma_lb_dns]
}

resource "aws_route53_record" "users_api_record" {
  zone_id = "Z0959434624C4DPQXHIJ"
  name    = "useraccounts-api.beta.gamma.com"
  type    = "CNAME"
  ttl     = 300
  records = [var.gamma_lb_dns]
}

resource "aws_route53_record" "gamenegine_api_record" {
  zone_id = "Z0959434624C4DPQXHIJ"
  name    = "gameengine-api.beta.gamma.com"
  type    = "CNAME"
  ttl     = 300
  records = [var.gamma_lb_dns]
}