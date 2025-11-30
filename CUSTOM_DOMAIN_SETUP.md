# Custom Domain Setup Guide: www.jenom.com

This guide walks you through configuring CloudFront to use your custom domain **www.jenom.com**.

## Prerequisites

- AWS Account ID: `615299732970`
- Domain: `www.jenom.com`
- Region: `us-east-1` (required for CloudFront ACM certificates)
- AWS CLI configured with appropriate credentials
- Terraform installed (v1.0+)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Custom Domain Flow                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  www.jenom.com (Browser Request)                             │
│         │                                                     │
│         ├──► DNS (CNAME or Route53 Alias)                    │
│         │                                                     │
│         └──► CloudFront Distribution                          │
│              (ACM Certificate: *.jenom.com or www.jenom.com) │
│                      │                                        │
│                      └──► S3 Bucket (via OAC)                │
│                           (Private Access Only)              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Request ACM Certificate

ACM certificates for CloudFront **must** be created in `us-east-1` region.

### Option A: Using AWS Console

1. **Navigate to ACM (us-east-1)**:
   ```
   https://console.aws.amazon.com/acm/home?region=us-east-1
   ```

2. **Request Certificate**:
   - Click **"Request a certificate"**
   - Select **"Request a public certificate"**
   - Click **"Next"**

3. **Domain Names**:
   ```
   Fully qualified domain name: www.jenom.com

   Optional: Add another name to this certificate
   - jenom.com (if you want both www and apex domain)
   ```

4. **Validation Method**:
   - Select **"DNS validation"** (recommended)
   - Click **"Next"**

5. **Tags** (optional):
   ```
   Key: Project         Value: Resume-Generator
   Key: Environment     Value: prod
   Key: ManagedBy       Value: Terraform
   ```

6. **Review and Request**:
   - Review settings
   - Click **"Request"**

7. **DNS Validation**:
   - Copy CNAME record name and value
   - Add to your DNS provider (see Step 3)
   - Wait for validation (5-30 minutes)

8. **Copy ARN**:
   ```
   arn:aws:acm:us-east-1:615299732970:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```

### Option B: Using AWS CLI

```bash
# 1. Request certificate
aws acm request-certificate \
  --domain-name www.jenom.com \
  --validation-method DNS \
  --region us-east-1 \
  --tags Key=Project,Value=Resume-Generator Key=Environment,Value=prod \
  --idempotency-token resume-cert-$(date +%s)

# Output:
{
  "CertificateArn": "arn:aws:acm:us-east-1:615299732970:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
}

# 2. Get DNS validation records
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:615299732970:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord'

# Output:
{
  "Name": "_XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www.jenom.com.",
  "Type": "CNAME",
  "Value": "_YYYYYYYYYYYYYYYYYYYYYYYYYYY.acm-validations.aws."
}

# 3. Check certificate status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:615299732970:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
  --region us-east-1 \
  --query 'Certificate.Status'

# Should return: "ISSUED" (after DNS validation completes)
```

### Option C: Using Terraform (Recommended)

Create `terraform/acm_certificate.tf`:

```hcl
# ACM Certificate for www.jenom.com
resource "aws_acm_certificate" "jenom_cert" {
  provider          = aws.us_east_1  # Must be us-east-1 for CloudFront
  domain_name       = "www.jenom.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "www.jenom.com"
    Project     = "Resume-Generator"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

# DNS validation records (if using Route53)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.jenom_cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.jenom.zone_id
}

# Wait for validation
resource "aws_acm_certificate_validation" "jenom_cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.jenom_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route53 zone data source
data "aws_route53_zone" "jenom" {
  name         = "jenom.com"
  private_zone = false
}

# Output certificate ARN
output "acm_certificate_arn" {
  value       = aws_acm_certificate.jenom_cert.arn
  description = "ARN of ACM certificate for www.jenom.com"
}
```

Add provider alias in `terraform/providers.tf`:

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
```

## Step 2: Update Terraform Configuration

### Create `terraform/terraform.tfvars`

```hcl
# Custom domain configuration
custom_domain = "www.jenom.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:615299732970:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

# CloudFront settings
enable_cloudfront = true
cloudfront_price_class = "PriceClass_100"

# Optional: Enable logging
enable_cloudfront_logging = false

# Optional: Geo restrictions
geo_restriction_type = "none"
geo_restriction_locations = []
```

### Verify Variables

Check `terraform/variables.tf` already has these defined:

```bash
cd terraform
grep -A 5 "custom_domain" variables.tf
grep -A 5 "acm_certificate_arn" variables.tf
```

## Step 3: DNS Configuration

You need to create a DNS record pointing `www.jenom.com` to your CloudFront distribution.

### Option A: Route53 (Recommended)

If your domain is hosted in Route53:

```hcl
# Add to terraform/route53.tf

data "aws_route53_zone" "jenom" {
  name         = "jenom.com"
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.jenom.zone_id
  name    = "www.jenom.com"
  type    = "A"

  alias {
    name                   = module.cloudfront[0].cloudfront_domain_name
    zone_id                = module.cloudfront[0].cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

output "www_jenom_url" {
  value       = "https://${aws_route53_record.www.name}"
  description = "Custom domain URL"
}
```

**Benefits of Route53 Alias**:
- No DNS query charges
- Health checks support
- Automatic IP updates
- Better performance

### Option B: External DNS Provider

If using GoDaddy, Namecheap, Cloudflare, etc:

1. **Get CloudFront Domain Name**:
   ```bash
   cd terraform
   terraform output cloudfront_domain_name
   # Example: d1234567890abc.cloudfront.net
   ```

2. **Create CNAME Record**:
   ```
   Type:  CNAME
   Name:  www
   Value: d1234567890abc.cloudfront.net
   TTL:   3600 (or Auto)
   ```

3. **Example: Namecheap**:
   - Go to Domain List → Manage → Advanced DNS
   - Add Record:
     - Type: CNAME Record
     - Host: www
     - Value: d1234567890abc.cloudfront.net
     - TTL: Automatic

4. **Example: Cloudflare**:
   - Go to DNS → Add record
   - Type: CNAME
   - Name: www
   - Target: d1234567890abc.cloudfront.net
   - Proxy status: DNS only (disable Cloudflare proxy)
   - TTL: Auto

## Step 4: Deploy Configuration

### 4.1 Initialize Terraform

```bash
cd terraform

# Initialize (downloads CloudFront module)
terraform init

# Validate configuration
terraform validate
```

### 4.2 Review Changes

```bash
# Preview changes
terraform plan

# Look for:
# + module.cloudfront[0].aws_cloudfront_distribution.s3_distribution
#   - aliases = ["www.jenom.com"]
#   - viewer_certificate {
#       acm_certificate_arn = "arn:aws:acm:..."
#     }
```

### 4.3 Apply Configuration

```bash
# Deploy infrastructure
terraform apply

# Type 'yes' when prompted
```

**Deployment Time**: 15-30 minutes (CloudFront distribution creation)

### 4.4 Verify Outputs

```bash
# Check outputs
terraform output

# Expected outputs:
cloudfront_domain_name     = "d1234567890abc.cloudfront.net"
cloudfront_distribution_id = "E1234567890ABC"
website_url                = "https://www.jenom.com"
```

## Step 5: DNS Validation

### Add DNS Validation Record

From Step 1, you received a CNAME record for ACM validation:

```
Name:  _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www.jenom.com
Type:  CNAME
Value: _YYYYYYYYYYYYYYYYYYYYYYYYYYY.acm-validations.aws
TTL:   300 (or Auto)
```

**Add this record to your DNS provider** (same place as Step 3).

### Wait for Validation

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:615299732970:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
  --region us-east-1 \
  --query 'Certificate.Status'

# Wait until: "ISSUED"
```

Validation typically takes 5-30 minutes.

## Step 6: Test Custom Domain

### 6.1 Check DNS Propagation

```bash
# Check DNS resolution
dig www.jenom.com

# Should resolve to CloudFront domain:
# www.jenom.com.    3600    IN    CNAME    d1234567890abc.cloudfront.net.

# Or using nslookup:
nslookup www.jenom.com

# Check from multiple locations:
# https://www.whatsmydns.net/#CNAME/www.jenom.com
```

### 6.2 Test HTTPS Access

```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://www.jenom.com

# Expected:
# HTTP/1.1 301 Moved Permanently
# Location: https://www.jenom.com/

# Test HTTPS
curl -I https://www.jenom.com

# Expected:
# HTTP/2 200
# content-type: text/html
# server: CloudFront
# x-cache: Hit from cloudfront
```

### 6.3 Test in Browser

1. Open browser
2. Navigate to: `https://www.jenom.com`
3. Check:
   - ✅ Page loads successfully
   - ✅ SSL certificate is valid (green lock icon)
   - ✅ Certificate shows: "Issued to: www.jenom.com"
   - ✅ No mixed content warnings

### 6.4 Verify SSL Certificate

```bash
# Check SSL certificate
openssl s_client -connect www.jenom.com:443 -servername www.jenom.com < /dev/null 2>&1 | grep -A 2 "subject="

# Expected:
# subject=CN=www.jenom.com
# issuer=C=US, O=Amazon, CN=Amazon RSA 2048 M02
```

## Step 7: Upload Content and Test

### Upload Website Content

```bash
# Upload your resume HTML
aws s3 cp index.html s3://milestone02-bedrock-website-bucket/ \
  --content-type text/html \
  --cache-control max-age=3600

# Upload other assets
aws s3 sync ./dist s3://milestone02-bedrock-website-bucket/ \
  --exclude "*.md" \
  --exclude ".git*"
```

### Invalidate CloudFront Cache

```bash
# Get distribution ID
DISTRIBUTION_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)

# Invalidate all files
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"

# Monitor invalidation
aws cloudfront get-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --id I1234567890ABC
```

### Test Final URL

```bash
# Test custom domain
curl -I https://www.jenom.com

# Should return:
# HTTP/2 200
# content-type: text/html
# x-cache: Miss from cloudfront (first request)
# x-cache: Hit from cloudfront (subsequent requests)
```

## Troubleshooting

### Issue: Certificate Stuck in "Pending Validation"

**Cause**: DNS validation record not added or incorrect.

**Solution**:
```bash
# 1. Check DNS validation record exists
dig _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www.jenom.com CNAME

# 2. Verify record value matches ACM
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:615299732970:certificate/XXXXXXXX \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord'

# 3. Wait for DNS propagation (up to 48 hours, usually < 30 mins)
```

### Issue: DNS Not Resolving

**Cause**: CNAME record not created or DNS not propagated.

**Solution**:
```bash
# Check DNS
dig www.jenom.com

# If not resolving:
# 1. Verify CNAME record in DNS provider
# 2. Wait for DNS propagation (up to 48 hours)
# 3. Check from multiple locations: whatsmydns.net
```

### Issue: SSL Certificate Error in Browser

**Cause**: ACM certificate not attached to CloudFront or certificate ARN incorrect.

**Solution**:
```bash
# 1. Verify certificate ARN in terraform.tfvars
cat terraform/terraform.tfvars | grep acm_certificate_arn

# 2. Check CloudFront configuration
aws cloudfront get-distribution \
  --id E1234567890ABC \
  --query 'Distribution.DistributionConfig.ViewerCertificate'

# 3. Re-apply Terraform
cd terraform
terraform apply -target=module.cloudfront
```

### Issue: 403 Forbidden

**Cause**: Content not uploaded or CloudFront cache issue.

**Solution**:
```bash
# 1. Check S3 bucket has content
aws s3 ls s3://milestone02-bedrock-website-bucket/

# 2. Upload index.html
aws s3 cp index.html s3://milestone02-bedrock-website-bucket/

# 3. Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

### Issue: "No 'Access-Control-Allow-Origin' header"

**Cause**: CORS configuration issue.

**Solution**: Already handled by CloudFront managed origin request policy (line 39 in main.tf).

### Issue: Custom Domain Not Working, CloudFront Default Works

**Symptom**:
- ✅ `https://d1234567890abc.cloudfront.net` works
- ❌ `https://www.jenom.com` doesn't work

**Cause**: DNS not pointing to CloudFront.

**Solution**:
```bash
# 1. Check DNS CNAME record
dig www.jenom.com

# Should show:
# www.jenom.com.    3600    IN    CNAME    d1234567890abc.cloudfront.net.

# 2. If not, add CNAME record in DNS provider
```

## Security Considerations

### HTTPS Only

Configuration enforces HTTPS:
```hcl
viewer_protocol_policy = "redirect-to-https"  # All HTTP → HTTPS
minimum_protocol_version = "TLSv1.2_2021"     # TLS 1.2+ only
```

### Certificate Validation

- ACM certificates are **free** and **automatically renewed**
- DNS validation is **recommended** over email validation
- Certificates must be in **us-east-1** for CloudFront

### Domain Verification

Only you can validate the certificate because:
- DNS validation requires adding CNAME to your domain
- Proves you control the domain
- Prevents unauthorized certificate issuance

## Cost Breakdown

### ACM Certificate
```
Cost: FREE (for public certificates)
Renewal: Automatic (no action required)
```

### CloudFront with Custom Domain
```
Data Transfer (First 10 TB): $0.085/GB
Requests (HTTPS): $0.0100/10,000
SSL/TLS Certificates: FREE (when using ACM)
Total (10K pageviews): ~$0.05/month
```

### Route53 (if used)
```
Hosted Zone: $0.50/month
DNS Queries (Standard): $0.40/million (first 1 billion)
Alias Queries: FREE
Total: ~$0.50/month
```

## Next Steps

### 1. Configure CI/CD

Update `.github/workflows/deploy_prod.yml`:

```yaml
- name: Invalidate CloudFront Cache
  run: |
    cd terraform
    DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
    aws cloudfront create-invalidation \
      --distribution-id $DISTRIBUTION_ID \
      --paths "/*"

- name: Output Website URL
  run: |
    echo "Website URL: https://www.jenom.com"
```

### 2. Add Apex Domain (Optional)

To support both `www.jenom.com` and `jenom.com`:

1. **Update ACM Certificate**:
   ```hcl
   domain_name = "jenom.com"
   subject_alternative_names = ["www.jenom.com"]
   ```

2. **Update CloudFront Aliases**:
   ```hcl
   aliases = ["jenom.com", "www.jenom.com"]
   ```

3. **Add Route53 Record for Apex**:
   ```hcl
   resource "aws_route53_record" "apex" {
     zone_id = data.aws_route53_zone.jenom.zone_id
     name    = "jenom.com"
     type    = "A"

     alias {
       name                   = module.cloudfront[0].cloudfront_domain_name
       zone_id                = module.cloudfront[0].cloudfront_hosted_zone_id
       evaluate_target_health = false
     }
   }
   ```

### 3. Enable Monitoring

```bash
# CloudFront requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=E1234567890ABC \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# 4xx/5xx error rates
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name 4xxErrorRate \
  --dimensions Name=DistributionId,Value=E1234567890ABC \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### 4. Enable WAF (Optional)

For additional security:

```hcl
# terraform/waf.tf
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider = aws.us_east_1  # Must be us-east-1 for CloudFront
  name     = "resume-cloudfront-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

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

# Update CloudFront module call in main.tf
web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn
```

**WAF Cost**: ~$5/month base + $1/million requests

## Summary Checklist

- [ ] ACM certificate requested for www.jenom.com in us-east-1
- [ ] DNS validation CNAME record added
- [ ] Certificate status shows "ISSUED"
- [ ] terraform.tfvars updated with custom_domain and acm_certificate_arn
- [ ] Terraform applied successfully
- [ ] DNS CNAME record created pointing to CloudFront distribution
- [ ] DNS propagation complete (dig www.jenom.com)
- [ ] HTTPS test successful (curl https://www.jenom.com)
- [ ] SSL certificate valid in browser
- [ ] Content uploaded to S3
- [ ] CloudFront cache invalidated
- [ ] Website accessible at https://www.jenom.com

## References

- [CloudFront Custom Domains](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html)
- [ACM Certificate Validation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html)
- [Route53 Alias Records](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html)
- [CloudFront SSL/TLS](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-https.html)

---

**Your custom domain https://www.jenom.com is ready for deployment!**
