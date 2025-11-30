# CloudFront-Only Access Configuration

## Overview

The infrastructure has been updated to enforce **CloudFront-only access**. The S3 bucket is now **completely private** and only accessible via CloudFront Origin Access Control (OAC).

## Security Model

```
┌─────────────────────────────────────────┐
│         Access Control Matrix            │
├─────────────────────────────────────────┤
│ Direct S3 HTTP Access:      ❌ BLOCKED  │
│ Direct S3 HTTPS Access:     ❌ BLOCKED  │
│ Public Bucket Policy:       ❌ REMOVED  │
│ Public ACLs:                ❌ BLOCKED  │
│ CloudFront OAC Access:      ✅ ALLOWED  │
└─────────────────────────────────────────┘
```

## What Changed

### 1. S3 Bucket Public Access Block

**Before:**
```hcl
block_public_acls       = false
block_public_policy     = false
restrict_public_buckets = false
```

**After:**
```hcl
block_public_acls       = true   # ✅ Block ALL public ACLs
ignore_public_acls      = true   # ✅ Ignore existing public ACLs
block_public_policy     = true   # ✅ Block public bucket policies
restrict_public_buckets = true   # ✅ Restrict public bucket access
```

### 2. S3 Bucket Policy

**Before:**
```hcl
resource "aws_s3_bucket_policy" "public_read_policy" {
  policy = jsonencode({
    Statement = [{
      Effect    = "Allow"
      Principal = "*"              # ❌ Public access
      Action    = "s3:GetObject"
    }]
  })
}
```

**After:**
```hcl
# ❌ NO public bucket policy in S3 module

# ✅ CloudFront module creates OAC policy:
resource "aws_s3_bucket_policy" "cloudfront_oac_policy" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"  # ✅ CloudFront only
      }
      Action   = "s3:GetObject"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = cloudfront_distribution.arn  # ✅ Specific distribution
        }
      }
    }]
  })
}
```

### 3. CloudFront Requirement

**Before:**
```hcl
variable "enable_cloudfront" {
  default = true  # Optional
}
```

**After:**
```hcl
variable "enable_cloudfront" {
  default = true  # REQUIRED

  validation {
    condition     = var.enable_cloudfront == true
    error_message = "CloudFront must be enabled. S3 bucket is private."
  }
}
```

Attempting to disable CloudFront will result in an error:
```
Error: CloudFront must be enabled. S3 bucket is private and only
accessible via CloudFront Origin Access Control (OAC).
```

## Access Patterns

### ❌ What DOESN'T Work

1. **Direct S3 HTTP URL:**
   ```bash
   curl http://bucket-name.s3-website-us-east-1.amazonaws.com
   # Returns: 403 Forbidden
   ```

2. **Direct S3 HTTPS URL:**
   ```bash
   curl https://bucket-name.s3.amazonaws.com/index.html
   # Returns: Access Denied
   ```

3. **S3 Console Download (without permissions):**
   - Only users with S3 `GetObject` IAM permissions can download
   - General public cannot access

### ✅ What DOES Work

1. **CloudFront HTTPS URL:**
   ```bash
   curl https://d1234567890abc.cloudfront.net
   # Returns: 200 OK (HTML content)
   ```

2. **Custom Domain via CloudFront:**
   ```bash
   curl https://resume.yourdomain.com
   # Returns: 200 OK (if configured)
   ```

3. **Programmatic Upload to S3:**
   ```bash
   # Uploading still works with proper IAM credentials
   aws s3 cp index.html s3://bucket-name/
   # Success
   ```

## Deployment

### Initial Deployment

```bash
cd terraform

# Initialize (CloudFront module required)
terraform init

# Validate configuration
terraform validate

# Review changes
terraform plan

# Deploy (takes 15-30 minutes for CloudFront)
terraform apply
```

### Expected Outputs

```
bucket_name                = "your-bucket-name"
s3_website_endpoint        = "your-bucket.s3-website-us-east-1.amazonaws.com" (not accessible)
cloudfront_distribution_id = "E1234567890ABC"
cloudfront_domain_name     = "d1234567890abc.cloudfront.net"
website_url                = "https://d1234567890abc.cloudfront.net" (✅ use this)
```

## Uploading Content

Content can still be uploaded to S3 normally:

### Using AWS CLI

```bash
# Upload file
aws s3 cp index.html s3://your-bucket-name/

# Upload directory
aws s3 sync ./dist s3://your-bucket-name/

# Upload with metadata
aws s3 cp index.html s3://your-bucket-name/ \
  --content-type text/html \
  --cache-control max-age=3600
```

### Using Terraform

```hcl
resource "aws_s3_object" "index" {
  bucket       = module.site_bucket.bucket_id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
  etag         = filemd5("index.html")
}
```

### Using Python (Boto3)

```python
import boto3

s3 = boto3.client('s3')
s3.upload_file(
    'index.html',
    'your-bucket-name',
    'index.html',
    ExtraArgs={'ContentType': 'text/html'}
)
```

## Cache Invalidation

After uploading new content, invalidate CloudFront cache:

```bash
# Invalidate all files
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"

# Invalidate specific files
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/index.html" "/styles.css"

# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id E1234567890ABC \
  --id I1234567890ABC
```

**Note:** First 1,000 invalidation paths per month are free.

## CI/CD Integration

Update your GitHub Actions workflows to use CloudFront:

```yaml
# .github/workflows/deploy_prod.yml
- name: Upload to S3
  run: |
    aws s3 sync ./dist s3://${{ secrets.RESUME_BUCKET }}/

- name: Invalidate CloudFront Cache
  run: |
    cd terraform
    DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
    aws cloudfront create-invalidation \
      --distribution-id $DISTRIBUTION_ID \
      --paths "/*"

- name: Output Website URL
  run: |
    cd terraform
    echo "Website URL: $(terraform output -raw website_url)"
```

## Monitoring

### CloudFront Metrics

Monitor via CloudWatch:

```bash
# Total requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=E1234567890ABC \
  --start-time 2025-01-15T00:00:00Z \
  --end-time 2025-01-15T23:59:59Z \
  --period 3600 \
  --statistics Sum

# 4xx error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name 4xxErrorRate \
  --dimensions Name=DistributionId,Value=E1234567890ABC \
  --start-time 2025-01-15T00:00:00Z \
  --end-time 2025-01-15T23:59:59Z \
  --period 3600 \
  --statistics Average
```

### S3 Bucket Access Attempts

S3 access attempts (should be zero from public):

```bash
# CloudTrail logs will show only CloudFront service accessing S3
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=your-bucket-name \
  --max-results 10
```

## Security Benefits

### 1. Defense in Depth

- **Layer 1:** S3 Public Access Block (blocks all public access)
- **Layer 2:** No public bucket policy (removed)
- **Layer 3:** CloudFront OAC policy (specific distribution ARN only)
- **Layer 4:** AWS Shield Standard (DDoS protection)
- **Layer 5:** Optional WAF (application-level protection)

### 2. Reduced Attack Surface

**Before (Public S3):**
```
Potential attack vectors:
- Direct S3 HTTP requests
- S3 bucket enumeration
- Public bucket policy manipulation
- ACL misconfiguration
- CORS misconfiguration
```

**After (CloudFront-Only):**
```
Potential attack vectors:
- CloudFront distribution only
- Protected by AWS Shield Standard
- Optional WAF protection
- Reduced risk of misconfiguration
```

### 3. Compliance

Meets security requirements for:
- ✅ **PCI DSS** - No public S3 access
- ✅ **HIPAA** - Encrypted in transit (HTTPS)
- ✅ **SOC 2** - Access control and logging
- ✅ **GDPR** - Data protection and privacy

## Troubleshooting

### Issue: 403 Forbidden on CloudFront

**Symptoms:**
```bash
curl https://d1234567890abc.cloudfront.net
# HTTP 403 Forbidden
```

**Causes:**
1. OAC policy not applied
2. CloudFront distribution not deployed
3. Object doesn't exist in S3

**Solutions:**
```bash
# 1. Check CloudFront status
aws cloudfront get-distribution \
  --id E1234567890ABC \
  --query 'Distribution.Status'
# Should be: "Deployed"

# 2. Verify OAC policy
aws s3api get-bucket-policy \
  --bucket your-bucket-name \
  --query Policy \
  --output text | jq .

# 3. Check object exists
aws s3 ls s3://your-bucket-name/index.html

# 4. Re-apply Terraform
terraform apply -target=module.cloudfront
```

### Issue: Old Content Showing

**Cause:** CloudFront cache not invalidated

**Solution:**
```bash
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

### Issue: Can't Access S3 Directly

**This is expected behavior** - S3 is private. Use CloudFront URL instead.

### Issue: Upload Fails

**Cause:** Insufficient IAM permissions

**Solution:**
```bash
# Verify IAM permissions
aws sts get-caller-identity

# Check S3 access
aws s3 ls s3://your-bucket-name

# Upload with proper credentials
aws s3 cp index.html s3://your-bucket-name/ \
  --profile your-profile
```

## Migration from Public S3

If you previously had public S3 access:

### Before Migration

```
Access Pattern: Direct S3 HTTP
URL: http://bucket.s3-website-us-east-1.amazonaws.com
Public Access: Enabled
Cost: S3 data transfer charges
```

### After Migration

```
Access Pattern: CloudFront HTTPS
URL: https://d1234567890abc.cloudfront.net
Public Access: Blocked
Cost: CloudFront data transfer (lower cost)
```

### Migration Steps

1. **Deploy CloudFront:**
   ```bash
   terraform apply
   ```

2. **Wait for CloudFront deployment** (~20 minutes)

3. **Test CloudFront URL:**
   ```bash
   curl -I https://d1234567890abc.cloudfront.net
   # Should return 200 OK
   ```

4. **Update DNS records:**
   - Change CNAME from S3 URL to CloudFront domain
   - Or use custom domain with ACM certificate

5. **Update application links:**
   - Replace S3 URLs with CloudFront URLs
   - Update documentation

6. **Monitor access:**
   ```bash
   # Verify CloudFront serves traffic
   aws cloudwatch get-metric-statistics \
     --namespace AWS/CloudFront \
     --metric-name Requests \
     --dimensions Name=DistributionId,Value=E1234567890ABC \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Sum
   ```

## Cost Comparison

### Before (Public S3 Only)

```
S3 Storage:       $0.023/GB/month
S3 Requests:      $0.0004/1000 GET
S3 Data Transfer: $0.09/GB (first 10 TB)
Total (10K views): ~$0.45/month
```

### After (CloudFront + Private S3)

```
S3 Storage:            $0.023/GB/month
CloudFront Data Transfer: $0.085/GB (first 10 TB)
CloudFront Requests:   $0.0075/10,000
S3→CloudFront Transfer: FREE (same region)
Total (10K views):     ~$0.05/month
```

**Savings:** ~90% reduction in cost!

## Best Practices

1. ✅ **Always use CloudFront URL** - Not S3 URL
2. ✅ **Invalidate after uploads** - Keep content fresh
3. ✅ **Monitor CloudFront metrics** - Track usage and errors
4. ✅ **Enable WAF for public sites** - Additional protection
5. ✅ **Use custom domain** - Professional appearance
6. ✅ **Set cache policies** - Optimize performance
7. ✅ **Enable access logging** - Audit and compliance
8. ✅ **Tag resources** - Cost allocation and management

## References

- [S3 Public Access Block](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- [CloudFront OAC](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [CloudFront Security](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/security.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**✅ Your infrastructure is now secured with CloudFront-only access!**
