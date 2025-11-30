# Quick Start: Deploy www.jenom.com

Fast-track deployment guide for setting up www.jenom.com with CloudFront and SSL.

## TL;DR

```bash
# 1. Request ACM certificate
aws acm request-certificate \
  --domain-name www.jenom.com \
  --validation-method DNS \
  --region us-east-1

# 2. Add DNS validation CNAME (from ACM output)

# 3. Create terraform.tfvars
cat > terraform/terraform.tfvars <<EOF
custom_domain = "www.jenom.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:615299732970:certificate/YOUR-CERT-ID"
EOF

# 4. Deploy
cd terraform
terraform init
terraform apply

# 5. Add DNS CNAME: www → CloudFront domain

# 6. Test
curl https://www.jenom.com
```

## Step-by-Step Deployment

### Step 1: Request SSL Certificate (5 minutes)

```bash
# Request certificate in us-east-1 (required for CloudFront)
aws acm request-certificate \
  --domain-name www.jenom.com \
  --validation-method DNS \
  --region us-east-1 \
  --tags Key=Project,Value=Resume-Generator \
  --idempotency-token jenom-cert-$(date +%s)
```

**Output:**
```json
{
  "CertificateArn": "arn:aws:acm:us-east-1:615299732970:certificate/12345678-1234-1234-1234-123456789abc"
}
```

**Save this ARN** - you'll need it for terraform.tfvars.

### Step 2: Get DNS Validation Record (1 minute)

```bash
# Replace with your certificate ARN from Step 1
CERT_ARN="arn:aws:acm:us-east-1:615299732970:certificate/12345678-1234-1234-1234-123456789abc"

# Get validation record
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
  --output table
```

**Output:**
```
-----------------------------------------------------------------------
|                        ResourceRecord                                |
+------+---------------------------------------------------------------+
| Name | _a1b2c3d4e5f6.www.jenom.com.                                 |
| Type | CNAME                                                         |
| Value| _x1y2z3a4b5c6.acm-validations.aws.                           |
+------+---------------------------------------------------------------+
```

### Step 3: Add DNS Validation Record (2 minutes)

Add this CNAME to your DNS provider (GoDaddy, Namecheap, Route53, etc.):

```
Type:  CNAME
Name:  _a1b2c3d4e5f6.www
Value: _x1y2z3a4b5c6.acm-validations.aws.
TTL:   300 (or Auto)
```

**Wait 5-30 minutes** for validation to complete.

**Check status:**
```bash
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.Status'

# Wait for: "ISSUED"
```

### Step 4: Configure Terraform (2 minutes)

```bash
# Navigate to terraform directory
cd terraform

# Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
nano terraform.tfvars
```

**Update these two lines:**
```hcl
custom_domain = "www.jenom.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:615299732970:certificate/12345678-1234-1234-1234-123456789abc"
```

**Or use command line:**
```bash
cat > terraform/terraform.tfvars <<'EOF'
# AWS Configuration
aws_region     = "us-east-1"
aws_account_id = "615299732970"
environment    = "prod"

# S3 Bucket
bucket_name      = "milestone02-bedrock-website-bucket"
site_bucket_name = "milestone02-bedrock-website-bucket"

# GitHub Actions
github_repo = "redLUIT/redLUIT_Nov2025_AWSBedRockProject02"

# Terraform State
tfstate_bucket      = "ec2-shutdown-lambda-bucket"
tfstate_key         = "bedrock-project02/prod/terraform.tfstate"
dynamodb_lock_table = "dyning_table"

# Custom Domain Configuration
custom_domain       = "www.jenom.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:615299732970:certificate/12345678-1234-1234-1234-123456789abc"

# CloudFront Settings
enable_cloudfront      = true
cloudfront_price_class = "PriceClass_100"
geo_restriction_type   = "none"
geo_restriction_locations = []

# Logging (optional)
enable_cloudfront_logging = false
cloudfront_logging_bucket = ""
cloudfront_logging_prefix = "cloudfront-logs/"

# WAF (optional)
web_acl_id = ""
EOF
```

### Step 5: Deploy Infrastructure (20-30 minutes)

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Deploy
terraform apply
# Type 'yes' when prompted
```

**Deployment includes:**
- ✅ S3 bucket (private, CloudFront-only access)
- ✅ CloudFront distribution with OAC
- ✅ SSL/TLS certificate attached
- ✅ DynamoDB tables
- ✅ IAM roles for GitHub Actions

**This takes 15-30 minutes** due to CloudFront global distribution.

### Step 6: Get CloudFront Domain (1 minute)

```bash
# After deployment completes, get CloudFront domain
cd terraform
terraform output cloudfront_domain_name
```

**Output:**
```
d1a2b3c4d5e6f7.cloudfront.net
```

### Step 7: Add Website DNS Record (2 minutes)

Add CNAME to your DNS provider:

```
Type:  CNAME
Name:  www
Value: d1a2b3c4d5e6f7.cloudfront.net
TTL:   3600 (or Auto)
```

**Provider Examples:**

**GoDaddy:**
- My Products → DNS → Add
- Type: CNAME, Name: www, Points to: d1a2b3c4d5e6f7.cloudfront.net

**Namecheap:**
- Domain List → Manage → Advanced DNS → Add New Record
- Type: CNAME, Host: www, Value: d1a2b3c4d5e6f7.cloudfront.net

**Route53:**
```bash
# Using AWS CLI (automated)
ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name jenom.com \
  --query 'HostedZones[0].Id' \
  --output text | cut -d'/' -f3)

CF_DOMAIN=$(cd terraform && terraform output -raw cloudfront_domain_name)

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
```

### Step 8: Wait for DNS Propagation (5-30 minutes)

```bash
# Check DNS propagation
dig www.jenom.com

# Expected output:
# www.jenom.com.    3600    IN    CNAME    d1a2b3c4d5e6f7.cloudfront.net.
```

**Check from multiple locations:**
```bash
# Online tools
open https://www.whatsmydns.net/#CNAME/www.jenom.com
```

### Step 9: Upload Website Content (2 minutes)

```bash
# Upload index.html
aws s3 cp index.html s3://milestone02-bedrock-website-bucket/ \
  --content-type text/html \
  --cache-control max-age=3600

# Or upload entire directory
aws s3 sync ./dist s3://milestone02-bedrock-website-bucket/ \
  --exclude "*.md" \
  --exclude ".git*"
```

### Step 10: Test Website (1 minute)

```bash
# Test HTTP → HTTPS redirect
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
# x-cache: Miss from cloudfront (first request)

# Verify SSL certificate
echo | openssl s_client -connect www.jenom.com:443 -servername www.jenom.com 2>&1 | grep "subject="

# Expected:
# subject=CN=www.jenom.com
```

**Test in browser:**
```bash
open https://www.jenom.com
```

**Verify:**
- ✅ Page loads
- ✅ Green lock icon (valid SSL)
- ✅ Certificate shows "www.jenom.com"
- ✅ URL shows "https://"

## Post-Deployment

### Invalidate CloudFront Cache

After uploading new content:

```bash
# Get distribution ID
DISTRIBUTION_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)

# Invalidate all files
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"

# Check invalidation status
aws cloudfront list-invalidations \
  --distribution-id $DISTRIBUTION_ID
```

**Note:** First 1,000 invalidation paths/month are free.

### Update GitHub Actions

Update `.github/workflows/deploy_prod.yml`:

```yaml
- name: Upload to S3
  run: |
    aws s3 sync ./dist s3://${{ secrets.RESUME_BUCKET }}/ \
      --delete \
      --cache-control max-age=3600

- name: Invalidate CloudFront
  run: |
    cd terraform
    DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
    aws cloudfront create-invalidation \
      --distribution-id $DISTRIBUTION_ID \
      --paths "/*"

- name: Output URL
  run: |
    echo "✅ Deployed to: https://www.jenom.com"
```

### Monitor Performance

```bash
# CloudFront requests (last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=$DISTRIBUTION_ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# 4xx error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name 4xxErrorRate \
  --dimensions Name=DistributionId,Value=$DISTRIBUTION_ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## Troubleshooting

### Certificate Validation Failing

```bash
# Check validation status
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0]'

# Verify DNS record
dig _a1b2c3d4e5f6.www.jenom.com CNAME

# If not found, add DNS validation CNAME again
```

### DNS Not Resolving

```bash
# Check DNS
dig www.jenom.com

# If not resolving:
# 1. Verify CNAME created in DNS provider
# 2. Wait for propagation (up to 48 hours)
# 3. Clear local DNS cache: sudo dscacheutil -flushcache
```

### SSL Certificate Error

```bash
# Verify certificate attached to CloudFront
aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --query 'Distribution.DistributionConfig.ViewerCertificate'

# Should show:
{
  "ACMCertificateArn": "arn:aws:acm:...",
  "SSLSupportMethod": "sni-only",
  "MinimumProtocolVersion": "TLSv1.2_2021"
}

# If missing, re-apply Terraform
cd terraform
terraform apply -target=module.cloudfront
```

### 403 Forbidden Error

```bash
# Check S3 bucket has content
aws s3 ls s3://milestone02-bedrock-website-bucket/

# If empty, upload content
aws s3 cp index.html s3://milestone02-bedrock-website-bucket/

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"
```

## Deployment Checklist

### Pre-Deployment
- [ ] AWS CLI configured
- [ ] Terraform installed
- [ ] Access to DNS provider (GoDaddy, Namecheap, Route53, etc.)
- [ ] Domain jenom.com exists

### Certificate Setup
- [ ] ACM certificate requested (us-east-1)
- [ ] DNS validation CNAME added
- [ ] Certificate status: "ISSUED"
- [ ] Certificate ARN saved

### Terraform Configuration
- [ ] terraform.tfvars created
- [ ] custom_domain = "www.jenom.com"
- [ ] acm_certificate_arn = "arn:aws:acm:..."
- [ ] terraform init completed
- [ ] terraform validate passed

### Infrastructure Deployment
- [ ] terraform apply completed
- [ ] CloudFront distribution created
- [ ] CloudFront domain obtained
- [ ] Outputs verified

### DNS Configuration
- [ ] Website CNAME created (www → CloudFront)
- [ ] DNS propagation complete
- [ ] dig www.jenom.com resolves

### Testing
- [ ] HTTP redirects to HTTPS
- [ ] HTTPS returns 200 OK
- [ ] SSL certificate valid
- [ ] Website loads in browser
- [ ] Content visible

### Post-Deployment
- [ ] Website content uploaded
- [ ] CloudFront cache invalidated
- [ ] GitHub Actions updated
- [ ] Monitoring configured

## Useful Commands

```bash
# Get all Terraform outputs
cd terraform && terraform output

# Check certificate status
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.Status'

# Check CloudFront status
aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --query 'Distribution.Status'

# Check DNS
dig www.jenom.com

# Test HTTPS
curl -I https://www.jenom.com

# Upload content
aws s3 cp index.html s3://milestone02-bedrock-website-bucket/

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"

# Monitor requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=$DISTRIBUTION_ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## Cost Estimate

### Monthly Costs (10,000 pageviews)

```
ACM Certificate:           FREE
CloudFront Data Transfer:  $0.085/GB × 0.1GB = $0.0085
CloudFront Requests:       $0.0100/10K × 1   = $0.0100
S3 Storage:                $0.023/GB × 0.01GB = $0.0002
S3 → CloudFront Transfer:  FREE (same region)
Route53 Hosted Zone:       $0.50 (if used)
---
Total:                     ~$0.52/month (with Route53)
                          ~$0.02/month (without Route53)
```

### Annual Costs

```
Without Route53: ~$0.24/year
With Route53:    ~$6.24/year
```

## Documentation

- **Complete Setup Guide**: CUSTOM_DOMAIN_SETUP.md
- **DNS Configuration**: DNS_CONFIGURATION_JENOM.md
- **CloudFront-Only Access**: CLOUDFRONT_ONLY_ACCESS.md
- **CloudFront Setup**: CLOUDFRONT_SETUP.md
- **Project README**: README.md

## Support

If you encounter issues:

1. Check troubleshooting section above
2. Review CUSTOM_DOMAIN_SETUP.md for detailed instructions
3. Verify all checklist items completed
4. Check AWS CloudWatch logs
5. Review Terraform plan output

---

**Total Deployment Time: ~45 minutes**
- Certificate request: 5 min
- DNS validation: 5-30 min
- Terraform: 2 min
- Infrastructure deployment: 15-30 min
- DNS propagation: 5-30 min
- Testing: 5 min

**Your website will be live at: https://www.jenom.com**
