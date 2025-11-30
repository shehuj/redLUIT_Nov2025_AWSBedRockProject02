# CloudFront Distribution Module

This module creates an AWS CloudFront distribution for secure HTTPS access to your S3-hosted resume website.

## Features

- ✅ **HTTPS/SSL** - Automatic HTTPS with CloudFront default certificate
- ✅ **Origin Access Control (OAC)** - Secure S3 access (replaces deprecated OAI)
- ✅ **Edge Caching** - Global content delivery with low latency
- ✅ **DDoS Protection** - AWS Shield Standard included
- ✅ **Custom Domain Support** - Optional custom domain with ACM certificate
- ✅ **Geo Restrictions** - Optional geographic access controls
- ✅ **WAF Integration** - Optional AWS WAF for advanced security
- ✅ **Access Logging** - Optional CloudFront access logs

## Security Benefits

### Origin Access Control (OAC)
- S3 bucket is **NOT publicly accessible**
- Only CloudFront can access S3 content via OAC
- Uses AWS Signature Version 4 for authentication
- More secure than legacy Origin Access Identity (OAI)

### HTTPS Enforcement
- All HTTP requests redirected to HTTPS
- TLS 1.2 minimum protocol version
- Supports custom SSL certificates via ACM

### Additional Security
- AWS Shield Standard (DDoS protection) included
- Optional AWS WAF for Layer 7 attack protection
- Optional geo-blocking by country code

## Usage

### Basic Usage (HTTPS with CloudFront Default Certificate)

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_name                  = "my-resume-bucket"
  bucket_id                    = aws_s3_bucket.this.id
  bucket_regional_domain_name  = aws_s3_bucket.this.bucket_regional_domain_name
  environment                  = "prod"
}
```

**Access URL:** `https://d1234567890abc.cloudfront.net`

### With Custom Domain

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_name                  = "my-resume-bucket"
  bucket_id                    = aws_s3_bucket.this.id
  bucket_regional_domain_name  = aws_s3_bucket.this.bucket_regional_domain_name
  environment                  = "prod"

  # Custom domain configuration
  custom_domain                = "resume.example.com"
  acm_certificate_arn          = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
}
```

**Important:** ACM certificate must be in `us-east-1` region for CloudFront.

### With Geo Restrictions

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_name                  = "my-resume-bucket"
  bucket_id                    = aws_s3_bucket.this.id
  bucket_regional_domain_name  = aws_s3_bucket.this.bucket_regional_domain_name

  # Allow only US and Canada
  geo_restriction_type         = "whitelist"
  geo_restriction_locations    = ["US", "CA"]
}
```

### With AWS WAF

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_name                  = "my-resume-bucket"
  bucket_id                    = aws_s3_bucket.this.id
  bucket_regional_domain_name  = aws_s3_bucket.this.bucket_regional_domain_name

  # AWS WAF Web ACL
  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn
}
```

### With Access Logging

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_name                  = "my-resume-bucket"
  bucket_id                    = aws_s3_bucket.this.id
  bucket_regional_domain_name  = aws_s3_bucket.this.bucket_regional_domain_name

  # Enable logging
  enable_logging               = true
  logging_bucket               = "my-logs-bucket.s3.amazonaws.com"
  logging_prefix               = "cloudfront-logs/"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `bucket_name` | S3 bucket name | `string` | - | yes |
| `bucket_id` | S3 bucket ID | `string` | - | yes |
| `bucket_regional_domain_name` | S3 bucket regional domain | `string` | - | yes |
| `environment` | Environment name | `string` | `"prod"` | no |
| `price_class` | CloudFront price class | `string` | `"PriceClass_100"` | no |
| `custom_domain` | Custom domain name | `string` | `""` | no |
| `acm_certificate_arn` | ACM certificate ARN (us-east-1) | `string` | `""` | no |
| `geo_restriction_type` | Geo restriction type | `string` | `"none"` | no |
| `geo_restriction_locations` | Country codes list | `list(string)` | `[]` | no |
| `enable_logging` | Enable access logging | `bool` | `false` | no |
| `logging_bucket` | S3 bucket for logs | `string` | `""` | no |
| `logging_prefix` | Log file prefix | `string` | `"cloudfront-logs/"` | no |
| `web_acl_id` | AWS WAF Web ACL ID | `string` | `""` | no |

### Price Classes

- `PriceClass_100` - US, Canada, Europe (cheapest)
- `PriceClass_200` - Above + Asia, Middle East, Africa
- `PriceClass_All` - All edge locations (most expensive)

## Outputs

| Name | Description |
|------|-------------|
| `distribution_id` | CloudFront distribution ID |
| `distribution_arn` | CloudFront distribution ARN |
| `distribution_domain_name` | CloudFront domain name |
| `distribution_hosted_zone_id` | Route 53 zone ID |
| `cloudfront_url` | Full HTTPS URL |
| `origin_access_control_id` | OAC ID |

## Cache Behavior

The module uses AWS managed cache policies:

- **Cache Policy:** `CachingOptimized` (658327ea-f89d-4fab-a63d-7e88639e58f6)
  - Caches based on query strings, headers, and cookies
  - Optimized TTL values for performance

- **Origin Request Policy:** `CORS-S3Origin` (88a5eaf4-2fd4-4709-b370-b4c650ea3fcf)
  - Forwards necessary headers for CORS
  - Optimized for S3 origins

## Custom Error Pages

The distribution handles:
- **403 Forbidden** → Returns `index.html` (for SPA routing)
- **404 Not Found** → Returns `index.html` (for SPA routing)

This enables client-side routing for single-page applications.

## Deployment Time

CloudFront distributions take **15-30 minutes** to deploy and propagate globally.

## Invalidation

To clear CloudFront cache after updating content:

```bash
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

**Note:** First 1,000 invalidation paths per month are free.

## Cost Estimation

Approximate costs (us-east-1, PriceClass_100):

- **Data Transfer Out:** $0.085 per GB (first 10 TB/month)
- **HTTP/HTTPS Requests:** $0.0075 per 10,000 requests
- **Invalidations:** First 1,000 paths/month free, then $0.005 per path

**Example:** 10,000 page views/month (~500 MB) = ~$0.05/month

## Security Best Practices

1. **Always use HTTPS** - Set `viewer_protocol_policy = "redirect-to-https"`
2. **Enable OAC** - Prevents direct S3 access
3. **Use TLS 1.2+** - Default minimum protocol version
4. **Enable logging** - Monitor access patterns
5. **Consider WAF** - Protection against OWASP Top 10
6. **Geo restrictions** - Limit access by country if needed

## Monitoring

Key CloudFront metrics in CloudWatch:

- `Requests` - Total number of requests
- `BytesDownloaded` - Data transferred to viewers
- `4xxErrorRate` - Client error rate
- `5xxErrorRate` - Server error rate
- `CacheHitRate` - Percentage of requests served from cache

## Troubleshooting

### Issue: 403 Forbidden Error

**Cause:** OAC policy not applied or S3 bucket policy incorrect

**Solution:**
```bash
# Verify OAC is attached to distribution
aws cloudfront get-distribution --id E1234567890ABC

# Check S3 bucket policy allows CloudFront
aws s3api get-bucket-policy --bucket my-resume-bucket
```

### Issue: Changes Not Appearing

**Cause:** CloudFront cache not invalidated

**Solution:**
```bash
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

### Issue: Certificate Error

**Cause:** ACM certificate not in us-east-1

**Solution:** Create certificate in us-east-1 region:
```bash
aws acm request-certificate \
  --domain-name resume.example.com \
  --validation-method DNS \
  --region us-east-1
```

## References

- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Origin Access Control](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
