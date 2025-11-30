# CloudFront Setup Guide

This guide explains how to deploy your resume website with CloudFront for secure HTTPS access.

## What CloudFront Adds

### Security
- ✅ **HTTPS/SSL** - Encrypted traffic with TLS 1.2+
- ✅ **Origin Access Control** - S3 bucket no longer publicly accessible
- ✅ **DDoS Protection** - AWS Shield Standard included
- ✅ **WAF Support** - Optional Web Application Firewall
- ✅ **Geo-Blocking** - Restrict access by country

### Performance
- ⚡ **Global CDN** - Content cached at 400+ edge locations
- ⚡ **Low Latency** - Serves content from nearest edge location
- ⚡ **Faster Loading** - Reduced time to first byte (TTFB)

### Features
- 🌐 **Custom Domains** - Use your own domain name
- 📊 **Access Logs** - Detailed request logging
- 📈 **Metrics** - CloudWatch monitoring built-in

---

## Quick Start (Default Configuration)

### 1. Deploy Infrastructure

CloudFront is **enabled by default**. Just run:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

After ~20 minutes, you'll see:

```
Outputs:
bucket_name = "your-bucket-name"
cloudfront_distribution_id = "E1234567890ABC"
cloudfront_domain_name = "d1234567890abc.cloudfront.net"
website_url = "https://d1234567890abc.cloudfront.net"
```

### 2. Access Your Resume

Open the `website_url` in your browser:

```
https://d1234567890abc.cloudfront.net
```

✅ **HTTPS enabled** - Secure connection
✅ **Global delivery** - Fast from anywhere

---

## Configuration Options

### Option 1: Disable CloudFront (HTTP Only)

If you want direct S3 access without CloudFront:

```hcl
# terraform.tfvars or variables.tf
enable_cloudfront = false
```

**Result:**
- S3 bucket becomes publicly readable
- Access via: `http://bucket-name.s3-website-us-east-1.amazonaws.com`
- No HTTPS (unless you configure manually)

### Option 2: Custom Domain Name

Use your own domain (e.g., `resume.yourdomain.com`):

#### Step 1: Request ACM Certificate

**Important:** Certificate must be in `us-east-1` region!

```bash
aws acm request-certificate \
  --domain-name resume.yourdomain.com \
  --validation-method DNS \
  --region us-east-1
```

#### Step 2: Validate Certificate

Add the DNS validation record to your domain's DNS:

```bash
# Get validation details
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/abc-123 \
  --region us-east-1
```

Add CNAME record to your DNS provider (e.g., Route53, Cloudflare, GoDaddy).

#### Step 3: Configure Terraform

```hcl
# terraform.tfvars
custom_domain        = "resume.yourdomain.com"
acm_certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
```

#### Step 4: Apply Configuration

```bash
terraform apply
```

#### Step 5: Update DNS

Point your domain to CloudFront:

```
Type: CNAME
Name: resume
Value: d1234567890abc.cloudfront.net
```

Or use Route53 Alias record:

```hcl
resource "aws_route53_record" "resume" {
  zone_id = "Z1234567890ABC"
  name    = "resume.yourdomain.com"
  type    = "A"

  alias {
    name                   = module.cloudfront[0].distribution_domain_name
    zone_id                = module.cloudfront[0].distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
```

### Option 3: Geo-Restrictions

Limit access to specific countries:

```hcl
# terraform.tfvars

# Allow only US and Canada
geo_restriction_type      = "whitelist"
geo_restriction_locations = ["US", "CA"]

# OR block specific countries
geo_restriction_type      = "blacklist"
geo_restriction_locations = ["CN", "RU"]
```

### Option 4: Enable Access Logging

Track all requests to your resume:

#### Step 1: Create Logging Bucket

```bash
aws s3 mb s3://my-cloudfront-logs
```

#### Step 2: Configure Terraform

```hcl
# terraform.tfvars
enable_cloudfront_logging = true
cloudfront_logging_bucket = "my-cloudfront-logs.s3.amazonaws.com"
cloudfront_logging_prefix = "resume-logs/"
```

Logs will be stored at:
```
s3://my-cloudfront-logs/resume-logs/E1234567890ABC.2025-01-15-12.ab123456.gz
```

### Option 5: AWS WAF Integration

Add Web Application Firewall for advanced protection:

#### Step 1: Create WAF Web ACL

```hcl
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name  = "resume-cloudfront-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudFrontWAF"
    sampled_requests_enabled   = true
  }
}
```

#### Step 2: Attach to CloudFront

```hcl
# terraform.tfvars
web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn
```

---

## Deployment Workflow

### Initial Deployment

```bash
# 1. Initialize Terraform
terraform init

# 2. Review plan
terraform plan

# 3. Apply (takes 15-30 minutes for CloudFront)
terraform apply

# 4. Wait for CloudFront deployment
aws cloudfront get-distribution \
  --id E1234567890ABC \
  --query 'Distribution.Status'
# Status should be "Deployed"
```

### Updating Content

When you update your resume:

```bash
# 1. Generate new HTML
python terraform/scripts/generate_and_deploy.py \
  --env prod \
  --bucket your-bucket-name \
  --region us-east-1

# 2. Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"

# 3. Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id E1234567890ABC \
  --id I1234567890ABC
```

**Note:** First 1,000 invalidation paths per month are free.

### Automation with GitHub Actions

Update your workflow to invalidate cache automatically:

```yaml
# .github/workflows/deploy_prod.yml
- name: Invalidate CloudFront Cache
  if: var.enable_cloudfront
  run: |
    DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
    aws cloudfront create-invalidation \
      --distribution-id $DISTRIBUTION_ID \
      --paths "/*"
```

---

## Monitoring & Troubleshooting

### Check Distribution Status

```bash
aws cloudfront get-distribution \
  --id E1234567890ABC \
  --query 'Distribution.Status'
```

### View CloudWatch Metrics

```bash
# Requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=E1234567890ABC \
  --start-time 2025-01-15T00:00:00Z \
  --end-time 2025-01-15T23:59:59Z \
  --period 3600 \
  --statistics Sum

# Cache Hit Rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=E1234567890ABC \
  --start-time 2025-01-15T00:00:00Z \
  --end-time 2025-01-15T23:59:59Z \
  --period 3600 \
  --statistics Average
```

### Common Issues

#### Issue 1: 403 Forbidden

**Symptom:** Can't access website, getting 403 error

**Cause:** Origin Access Control policy not applied

**Solution:**
```bash
# Re-apply Terraform
terraform apply -target=module.cloudfront
```

#### Issue 2: Changes Not Visible

**Symptom:** Updated resume but old version shows

**Cause:** CloudFront cache

**Solution:**
```bash
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

#### Issue 3: Certificate Error

**Symptom:** SSL certificate error or mismatch

**Cause:** Certificate not in us-east-1

**Solution:**
1. Request certificate in us-east-1:
   ```bash
   aws acm request-certificate \
     --domain-name resume.yourdomain.com \
     --validation-method DNS \
     --region us-east-1
   ```
2. Validate via DNS
3. Update `acm_certificate_arn` in terraform.tfvars

#### Issue 4: Slow Deployment

**Symptom:** Terraform apply taking very long

**Cause:** CloudFront distributions take 15-30 minutes to deploy

**Solution:** This is normal. Wait for completion.

---

## Cost Estimation

### CloudFront Pricing (PriceClass_100)

| Usage | Monthly Cost |
|-------|-------------|
| 10,000 page views (~500 MB) | ~$0.05 |
| 100,000 page views (~5 GB) | ~$0.50 |
| 1,000,000 page views (~50 GB) | ~$4.50 |

**Included:**
- AWS Shield Standard (DDoS protection) - Free
- 1,000 invalidation paths/month - Free
- TLS/SSL certificate (CloudFront default) - Free

**Optional Costs:**
- Custom domain with ACM - Free
- AWS WAF - $5/month + $1/million requests
- CloudFront logging - S3 storage costs

### Cost Optimization Tips

1. **Use PriceClass_100** (US, Canada, Europe) instead of All
2. **Cache aggressively** - Reduce origin requests
3. **Compress content** - Reduce data transfer
4. **Batch invalidations** - First 1,000 paths free/month
5. **Monitor usage** - Set CloudWatch billing alarms

---

## Security Best Practices

1. ✅ **Always use HTTPS** - Redirect HTTP to HTTPS
2. ✅ **Enable OAC** - S3 not publicly accessible
3. ✅ **Use TLS 1.2+** - Modern encryption only
4. ✅ **Enable WAF** - Protection for public sites
5. ✅ **Monitor logs** - Detect unusual patterns
6. ✅ **Geo-restrict** - Limit exposure if appropriate
7. ✅ **Set cache policies** - Prevent sensitive data caching

---

## Next Steps

1. ✅ Deploy CloudFront with defaults
2. 📝 Test access via HTTPS URL
3. 🔄 Set up cache invalidation in CI/CD
4. 🌐 (Optional) Configure custom domain
5. 🛡️ (Optional) Enable WAF for protection
6. 📊 (Optional) Enable access logging
7. 📈 Monitor CloudWatch metrics

---

## Reference Links

- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Origin Access Control](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)
- [ACM Certificate Guide](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)
