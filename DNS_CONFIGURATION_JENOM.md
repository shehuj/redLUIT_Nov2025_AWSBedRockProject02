# DNS Configuration Guide for www.jenom.com

Quick reference guide for configuring DNS records for your custom domain.

## Required DNS Records

You need to create **2 DNS records** for www.jenom.com:

### 1. ACM Certificate Validation (CNAME)

This validates your SSL/TLS certificate:

```
Type:  CNAME
Name:  _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www.jenom.com
Value: _YYYYYYYYYYYYYYYYYYYYYYYYYYY.acm-validations.aws.
TTL:   300 (or Auto)
```

**How to get these values:**
```bash
# Request certificate first
aws acm request-certificate \
  --domain-name www.jenom.com \
  --validation-method DNS \
  --region us-east-1

# Get validation record
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:615299732970:certificate/YOUR-CERT-ID \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord'
```

### 2. Website Access (CNAME or Alias)

This points your domain to CloudFront:

#### Option A: CNAME Record (Any DNS Provider)

```
Type:  CNAME
Name:  www
Value: d1234567890abc.cloudfront.net
TTL:   3600 (or Auto)
```

**How to get CloudFront domain:**
```bash
cd terraform
terraform output cloudfront_domain_name
# Output: d1234567890abc.cloudfront.net
```

#### Option B: Alias Record (Route53 Only - Recommended)

```hcl
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
```

**Benefits:**
- No DNS query charges
- Faster performance
- Automatic IP updates

## DNS Provider Configuration

### GoDaddy

1. Log in to GoDaddy
2. Go to **My Products** → **DNS**
3. Click **Add** under DNS Records

**ACM Validation Record:**
```
Type:  CNAME
Name:  _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www
Points to: _YYYYYYYYYYYYYYYYYYYYYYYYYYY.acm-validations.aws
TTL:   1 Hour
```

**Website CNAME:**
```
Type:  CNAME
Name:  www
Points to: d1234567890abc.cloudfront.net
TTL:   1 Hour
```

### Namecheap

1. Log in to Namecheap
2. Go to **Domain List** → **Manage**
3. Select **Advanced DNS** tab
4. Click **Add New Record**

**ACM Validation Record:**
```
Type:  CNAME Record
Host:  _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www
Value: _YYYYYYYYYYYYYYYYYYYYYYYYYYY.acm-validations.aws.
TTL:   Automatic
```

**Website CNAME:**
```
Type:  CNAME Record
Host:  www
Value: d1234567890abc.cloudfront.net
TTL:   Automatic
```

### Cloudflare

1. Log in to Cloudflare
2. Select your domain: **jenom.com**
3. Go to **DNS** → **Records**
4. Click **Add record**

**ACM Validation Record:**
```
Type:  CNAME
Name:  _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www
Target: _YYYYYYYYYYYYYYYYYYYYYYYYYYY.acm-validations.aws
Proxy status: DNS only (orange cloud OFF)
TTL:   Auto
```

**Website CNAME:**
```
Type:  CNAME
Name:  www
Target: d1234567890abc.cloudfront.net
Proxy status: DNS only (orange cloud OFF) ⚠️ IMPORTANT
TTL:   Auto
```

**⚠️ Cloudflare Warning:**
- **MUST disable Cloudflare proxy** (orange cloud OFF)
- If proxy is enabled, SSL certificate validation will fail
- CloudFront already provides CDN functionality

### Google Domains

1. Log in to Google Domains
2. Select **jenom.com**
3. Go to **DNS** tab
4. Scroll to **Custom resource records**

**ACM Validation Record:**
```
Name: _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www
Type: CNAME
TTL:  1H
Data: _YYYYYYYYYYYYYYYYYYYYYYYYYYY.acm-validations.aws.
```

**Website CNAME:**
```
Name: www
Type: CNAME
TTL:  1H
Data: d1234567890abc.cloudfront.net
```

### AWS Route53 (Recommended)

#### Using Terraform (Automated)

Create `terraform/route53.tf`:

```hcl
# Get existing hosted zone
data "aws_route53_zone" "jenom" {
  name         = "jenom.com"
  private_zone = false
}

# ACM certificate validation
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

# Website alias record
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

# IPv6 support (optional)
resource "aws_route53_record" "www_ipv6" {
  zone_id = data.aws_route53_zone.jenom.zone_id
  name    = "www.jenom.com"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront[0].cloudfront_domain_name
    zone_id                = module.cloudfront[0].cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# Outputs
output "www_jenom_url" {
  value       = "https://${aws_route53_record.www.name}"
  description = "Website URL with custom domain"
}
```

#### Using AWS Console

1. Go to **Route53** → **Hosted zones**
2. Select **jenom.com**
3. Click **Create record**

**ACM Validation:**
```
Record name: _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www
Record type: CNAME
Value:       _YYYYYYYYYYYYYYYYYYYYYYYYYYY.acm-validations.aws
TTL:         300
Routing policy: Simple routing
```

**Website Alias:**
```
Record name: www
Record type: A
Alias:       Yes
Route traffic to: Alias to CloudFront distribution
Distribution: d1234567890abc.cloudfront.net
Evaluate target health: No
```

#### Using AWS CLI

```bash
# Get hosted zone ID
ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name jenom.com \
  --query 'HostedZones[0].Id' \
  --output text | cut -d'/' -f3)

# Get CloudFront domain
cd terraform
CF_DOMAIN=$(terraform output -raw cloudfront_domain_name)

# Create alias record
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.jenom.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "'$CF_DOMAIN'",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'

# Note: Z2FDTNDATAQYW2 is CloudFront's hosted zone ID (constant for all distributions)
```

## Verification Steps

### 1. Check ACM Certificate Status

```bash
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:615299732970:certificate/YOUR-CERT-ID \
  --region us-east-1 \
  --query 'Certificate.Status'

# Wait for: "ISSUED"
# Time: 5-30 minutes after adding DNS validation record
```

### 2. Verify DNS Propagation

```bash
# Check validation CNAME
dig _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www.jenom.com CNAME

# Check website CNAME
dig www.jenom.com

# Should resolve to CloudFront:
# www.jenom.com.    3600    IN    CNAME    d1234567890abc.cloudfront.net.
```

**Check from multiple locations:**
- https://www.whatsmydns.net/#CNAME/www.jenom.com
- https://dnschecker.org/#CNAME/www.jenom.com

### 3. Test HTTPS Access

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
# server: CloudFront
```

### 4. Verify SSL Certificate

```bash
# Check SSL certificate
echo | openssl s_client -connect www.jenom.com:443 -servername www.jenom.com 2>&1 | grep -A 2 "subject="

# Expected:
# subject=CN=www.jenom.com
# issuer=C=US, O=Amazon, CN=Amazon RSA 2048 M02
```

## Troubleshooting

### ACM Certificate Stuck in "Pending Validation"

**Check DNS record exists:**
```bash
dig _XXXXXXXXXXXXXXXXXXXXXXXXXXXX.www.jenom.com CNAME
```

**If not found:**
1. Verify you added the CNAME to your DNS provider
2. Check for typos in record name/value
3. Wait for DNS propagation (up to 48 hours, usually < 30 mins)

### www.jenom.com Not Resolving

**Check DNS:**
```bash
dig www.jenom.com
```

**If not found:**
1. Verify CNAME record created in DNS provider
2. Check DNS propagation: https://www.whatsmydns.net/
3. Wait up to 48 hours for global propagation

### SSL Certificate Error in Browser

**Possible causes:**
1. ACM certificate not attached to CloudFront
2. Certificate ARN incorrect in terraform.tfvars
3. CloudFront not deployed yet

**Solution:**
```bash
# Verify CloudFront has certificate
cd terraform
terraform output cloudfront_distribution_id

aws cloudfront get-distribution \
  --id E1234567890ABC \
  --query 'Distribution.DistributionConfig.ViewerCertificate'

# Re-apply if needed
terraform apply -target=module.cloudfront
```

### CloudFront Default Domain Works, Custom Domain Doesn't

**Symptom:**
- ✅ https://d1234567890abc.cloudfront.net works
- ❌ https://www.jenom.com doesn't work

**Cause:** DNS CNAME not pointing to CloudFront

**Solution:**
```bash
# Verify DNS
dig www.jenom.com

# If not pointing to CloudFront, add CNAME record
```

## DNS Propagation Timeline

| Location | Typical Time | Maximum Time |
|----------|--------------|--------------|
| Local ISP | 5-10 minutes | 1 hour |
| Regional | 30 minutes | 6 hours |
| Global | 1-2 hours | 48 hours |

**Speed up propagation:**
1. Use lower TTL values (300-600 seconds)
2. Flush DNS cache locally: `sudo dscacheutil -flushcache` (macOS)
3. Use Google DNS (8.8.8.8) or Cloudflare DNS (1.1.1.1)

## Summary Checklist

### ACM Certificate Validation
- [ ] ACM certificate requested in us-east-1
- [ ] DNS validation CNAME record added to DNS provider
- [ ] DNS propagation complete (dig validation record)
- [ ] Certificate status shows "ISSUED"
- [ ] Certificate ARN copied to terraform.tfvars

### Website DNS
- [ ] CloudFront distribution created
- [ ] CloudFront domain obtained (terraform output)
- [ ] CNAME or Alias record created in DNS provider
- [ ] DNS propagation complete (dig www.jenom.com)
- [ ] DNS resolves to CloudFront domain

### Testing
- [ ] HTTP redirects to HTTPS (curl http://www.jenom.com)
- [ ] HTTPS returns 200 OK (curl https://www.jenom.com)
- [ ] SSL certificate valid (browser shows green lock)
- [ ] Website loads in browser (https://www.jenom.com)

## Quick Reference Commands

```bash
# Get CloudFront domain
cd terraform && terraform output cloudfront_domain_name

# Get certificate validation record
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:615299732970:certificate/YOUR-CERT-ID \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord'

# Check certificate status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:615299732970:certificate/YOUR-CERT-ID \
  --region us-east-1 \
  --query 'Certificate.Status'

# Verify DNS
dig www.jenom.com
dig _validation-record.www.jenom.com CNAME

# Test HTTPS
curl -I https://www.jenom.com

# Check SSL certificate
echo | openssl s_client -connect www.jenom.com:443 -servername www.jenom.com 2>&1 | grep subject=
```

## Next Steps

After DNS is configured and propagated:

1. **Upload content to S3:**
   ```bash
   aws s3 cp index.html s3://milestone02-bedrock-website-bucket/
   ```

2. **Invalidate CloudFront cache:**
   ```bash
   DISTRIBUTION_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)
   aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
   ```

3. **Test website:**
   ```bash
   curl https://www.jenom.com
   ```

4. **Update CI/CD pipelines** to use new URL

---

**For complete setup instructions, see: CUSTOM_DOMAIN_SETUP.md**
