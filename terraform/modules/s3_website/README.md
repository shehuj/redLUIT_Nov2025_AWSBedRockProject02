# S3 Website Module (CloudFront-Only Access)

This module creates an S3 bucket configured for static website hosting with **CloudFront Origin Access Control (OAC) only**. The bucket is **NOT publicly accessible**.

## Security Model

```
❌ Public Access: BLOCKED
✅ CloudFront OAC: ALLOWED
```

All public access is blocked at the bucket level. Only CloudFront can access the bucket content via Origin Access Control (OAC).

## Resources Created

- **S3 Bucket** - Static website hosting bucket
- **S3 Bucket Versioning** - Optional version control
- **S3 Website Configuration** - index.html/error.html settings
- **S3 Public Access Block** - Blocks ALL public access
- ~~S3 Bucket Policy~~ - Managed by CloudFront module (OAC policy)

## Usage

```hcl
module "site_bucket" {
  source      = "./modules/s3_website"
  bucket_name = "my-resume-bucket"

  tags = {
    Environment = "prod"
    Project     = "Resume"
  }
}

# CloudFront module must be used to enable access
module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_name                  = module.site_bucket.bucket_id
  bucket_id                    = module.site_bucket.bucket_id
  bucket_regional_domain_name  = module.site_bucket.bucket_regional_domain_name
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `bucket_name` | `string` | (required) | S3 bucket name (globally unique) |
| `enable_versioning` | `bool` | `false` | Enable S3 object versioning |
| `tags` | `map(string)` | `{}` | Additional tags for resources |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | S3 bucket ID |
| `bucket_arn` | S3 bucket ARN |
| `bucket_regional_domain_name` | Regional domain name for CloudFront origin |
| `website_endpoint` | S3 website endpoint (not publicly accessible) |

## Security Features

### Public Access Block

All four public access block settings are **enabled**:

```hcl
block_public_acls       = true  # Block public ACLs
ignore_public_acls      = true  # Ignore existing public ACLs
block_public_policy     = true  # Block public bucket policies
restrict_public_buckets = true  # Restrict public bucket access
```

### Access Control

- ❌ **Public Read**: Blocked
- ❌ **Public Write**: Blocked
- ❌ **Direct S3 Access**: Not allowed
- ✅ **CloudFront OAC**: Only allowed access method

### Bucket Policy

The bucket policy is **NOT created by this module**. Instead, the CloudFront module creates an OAC-specific policy that:
- Grants `s3:GetObject` permission to CloudFront service
- Restricts access to specific CloudFront distribution (via ARN condition)
- Uses AWS Signature Version 4 authentication

## Website Configuration

- **Index Document**: `index.html`
- **Error Document**: `error.html`

These are configured but **only accessible via CloudFront**, not directly from S3.

## Versioning

Object versioning can be enabled for:
- Rollback capability
- Accidental deletion protection
- Audit trail

```hcl
module "site_bucket" {
  source             = "./modules/s3_website"
  bucket_name        = "my-bucket"
  enable_versioning  = true
}
```

## Important Notes

### ⚠️ No Direct S3 Access

This bucket is configured for **CloudFront-only access**. Direct S3 URLs will **not work**:

```
❌ http://bucket-name.s3.amazonaws.com/index.html
❌ http://bucket-name.s3-website-us-east-1.amazonaws.com
✅ https://d1234567890abc.cloudfront.net (CloudFront only)
```

### ⚠️ CloudFront Required

You **must** use this module with the CloudFront module. Without CloudFront:
- Bucket content is inaccessible
- Website URLs return 403 Forbidden
- No way to view content

### ⚠️ Uploading Content

When uploading content to S3:

```bash
# Upload works fine
aws s3 cp index.html s3://my-bucket/index.html

# But direct access fails (403 Forbidden)
curl http://my-bucket.s3-website-us-east-1.amazonaws.com

# Must access via CloudFront (after invalidation)
curl https://d1234567890abc.cloudfront.net
```

## Migration from Public S3

If migrating from a publicly accessible S3 bucket:

### Before (Public Access)
```hcl
resource "aws_s3_bucket_public_access_block" {
  block_public_acls       = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" {
  policy = "Allow Principal:* Action:s3:GetObject"
}
```

### After (CloudFront-Only)
```hcl
resource "aws_s3_bucket_public_access_block" {
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# No public policy - CloudFront OAC policy instead
```

### Migration Steps

1. Deploy CloudFront distribution
2. Test access via CloudFront URL
3. Update DNS/links to CloudFront domain
4. Remove public S3 access (this module)
5. Monitor CloudFront metrics

## Troubleshooting

### Issue: 403 Forbidden on CloudFront

**Cause**: OAC policy not applied

**Solution**:
```bash
# Ensure CloudFront module is deployed
terraform apply -target=module.cloudfront

# Check bucket policy
aws s3api get-bucket-policy --bucket my-bucket
```

### Issue: Can't Access S3 Directly

**Expected behavior** - bucket is private. Use CloudFront URL instead.

### Issue: Upload Fails

**Cause**: Incorrect AWS credentials or permissions

**Solution**:
```bash
# Verify credentials can write to S3
aws s3 ls s3://my-bucket

# Upload with correct profile
aws s3 cp index.html s3://my-bucket/ --profile your-profile
```

## Cost

S3 costs for this configuration:
- **Storage**: ~$0.023/GB/month
- **Requests**: $0.0004/1000 PUT, $0.0004/1000 GET
- **Data Transfer**: Free (to CloudFront in same region)

**Note**: Direct S3 data transfer costs don't apply since access is only via CloudFront.

## Best Practices

1. ✅ **Always use CloudFront** - This module requires it
2. ✅ **Enable versioning** - For rollback capability
3. ✅ **Use lifecycle policies** - Clean up old versions
4. ✅ **Tag resources** - For cost allocation
5. ✅ **Monitor access** - Via CloudFront logs, not S3 logs

## Example: Complete Setup

```hcl
# 1. Create S3 bucket (private)
module "resume_bucket" {
  source             = "./modules/s3_website"
  bucket_name        = "my-resume-2025"
  enable_versioning  = true

  tags = {
    Environment = "prod"
    Project     = "Resume"
    Owner       = "DevOps Team"
  }
}

# 2. Create CloudFront distribution (required for access)
module "resume_cdn" {
  source = "./modules/cloudfront"

  bucket_name                  = module.resume_bucket.bucket_id
  bucket_id                    = module.resume_bucket.bucket_id
  bucket_regional_domain_name  = module.resume_bucket.bucket_regional_domain_name
  environment                  = "prod"
}

# 3. Upload content
resource "null_resource" "upload_resume" {
  provisioner "local-exec" {
    command = <<-EOT
      aws s3 cp index.html s3://${module.resume_bucket.bucket_id}/
    EOT
  }

  depends_on = [module.resume_bucket]
}

# 4. Output CloudFront URL
output "resume_url" {
  value = module.resume_cdn.cloudfront_url
}
```

## References

- [S3 Public Access Block](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- [CloudFront OAC](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [S3 Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
