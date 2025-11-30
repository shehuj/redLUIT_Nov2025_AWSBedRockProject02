# Route53 Configuration for shehuj.com
# This file configures DNS records for the custom domain

# Get the existing Route53 hosted zone for shehuj.com
data "aws_route53_zone" "primary" {
  name         = "shehuj.com"
  private_zone = false
}

# A Record (IPv4) - Alias to CloudFront Distribution
# This points shehuj.com to CloudFront
resource "aws_route53_record" "apex" {
  count   = var.enable_cloudfront && var.custom_domain != "" ? 1 : 0
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.custom_domain
  type    = "A"

  alias {
    name                   = module.cloudfront[0].distribution_domain_name
    zone_id                = module.cloudfront[0].distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA Record (IPv6) - Alias to CloudFront Distribution
# This provides IPv6 support for the website
resource "aws_route53_record" "apex_ipv6" {
  count   = var.enable_cloudfront && var.custom_domain != "" ? 1 : 0
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.custom_domain
  type    = "AAAA"

  alias {
    name                   = module.cloudfront[0].distribution_domain_name
    zone_id                = module.cloudfront[0].distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

# Optional: WWW subdomain (www.shehuj.com)
# Uncomment if you want to support www subdomain as well
# resource "aws_route53_record" "www" {
#   count   = var.enable_cloudfront && var.custom_domain != "" ? 1 : 0
#   zone_id = data.aws_route53_zone.primary.zone_id
#   name    = "www.${var.custom_domain}"
#   type    = "A"
#
#   alias {
#     name                   = module.cloudfront[0].distribution_domain_name
#     zone_id                = module.cloudfront[0].distribution_hosted_zone_id
#     evaluate_target_health = false
#   }
# }
