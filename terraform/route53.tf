# Route53 Configuration for www.jenom.com
# This file configures DNS records for the custom domain

# Get the existing Route53 hosted zone for www.jenom.com
# Note: This is a subdomain hosted zone (www.jenom.com) not an apex domain
data "aws_route53_zone" "jenom" {
  name         = "www.jenom.com"
  private_zone = false
}

# A Record (IPv4) - Alias to CloudFront Distribution
# This is the primary DNS record that points www.jenom.com to CloudFront
# Since the hosted zone is for www.jenom.com, we use the zone apex (empty name)
resource "aws_route53_record" "www" {
  count   = var.enable_cloudfront && var.custom_domain != "" ? 1 : 0
  zone_id = data.aws_route53_zone.jenom.zone_id
  name    = data.aws_route53_zone.jenom.name
  type    = "A"

  alias {
    name                   = module.cloudfront[0].distribution_domain_name
    zone_id                = module.cloudfront[0].distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA Record (IPv6) - Alias to CloudFront Distribution
# This provides IPv6 support for the website
# Since the hosted zone is for www.jenom.com, we use the zone apex (empty name)
resource "aws_route53_record" "www_ipv6" {
  count   = var.enable_cloudfront && var.custom_domain != "" ? 1 : 0
  zone_id = data.aws_route53_zone.jenom.zone_id
  name    = data.aws_route53_zone.jenom.name
  type    = "AAAA"

  alias {
    name                   = module.cloudfront[0].distribution_domain_name
    zone_id                = module.cloudfront[0].distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

# Optional: Apex domain redirect (jenom.com -> www.jenom.com)
# Uncomment if you want to redirect the root domain to www
# resource "aws_route53_record" "apex" {
#   zone_id = data.aws_route53_zone.jenom.zone_id
#   name    = "jenom.com"
#   type    = "A"
#
#   alias {
#     name                   = module.cloudfront[0].cloudfront_domain_name
#     zone_id                = module.cloudfront[0].cloudfront_hosted_zone_id
#     evaluate_target_health = false
#   }
# }
