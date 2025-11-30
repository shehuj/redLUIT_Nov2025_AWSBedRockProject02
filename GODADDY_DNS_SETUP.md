# GoDaddy DNS Setup for www.jenom.com

## ⚠️ CRITICAL: You MUST add these DNS records NOW!

Your ACM certificate is waiting for DNS validation. **You have 72 hours** to add this record or the certificate will fail again.

---

## Step 1: Add Certificate Validation Record (DO THIS FIRST!)

### DNS Record Details

```
Type:  CNAME
Host:  _33e8ad0a9e3f66a234ec5e6f103a48f1.www
Points to: _c1a81ff1831900d76da8bd3b6cbf5348.jkddzztszm.acm-validations.aws.
TTL:   1 Hour (default)
```

### GoDaddy Instructions

1. **Log in to GoDaddy**: https://dcc.godaddy.com/manage/dns

2. **Select your domain**: Click on **jenom.com**

3. **Click "DNS" or "Manage DNS"**

4. **Scroll to "Records" section**

5. **Click "Add" button**

6. **Fill in the form**:
   ```
   Type:      CNAME
   Host:      _33e8ad0a9e3f66a234ec5e6f103a48f1.www
   Points to: _c1a81ff1831900d76da8bd3b6cbf5348.jkddzztszm.acm-validations.aws.
   TTL:       1 Hour
   ```

7. **Click "Save"**

8. **IMPORTANT**: Leave this record in place permanently (it's needed for auto-renewal)

---

## Step 2: Wait for Certificate Validation (5-30 minutes)

### Check Validation Status

Run this command to check if validation is complete:

```bash
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:615299732970:certificate/b3c357ad-2711-42f8-9190-bff6a42fd45a \
  --region us-east-1 \
  --query 'Certificate.Status'
```

**Wait for**: `"ISSUED"`

**Typical wait time**: 5-30 minutes

---

## Step 3: Deploy Infrastructure

Once certificate shows "ISSUED", deploy with Terraform:

```bash
cd /Users/captcloud01/Documents/GitHub/redLUIT_Nov2025_AWSBedRockProject02/terraform

# Validate configuration
terraform validate

# Review changes
terraform plan

# Deploy (takes 15-30 minutes)
terraform apply

# Get CloudFront domain
terraform output cloudfront_domain_name
```

**Save the CloudFront domain** (example: d1234567890abc.cloudfront.net)

---

## Step 4: Add Website CNAME Record

After Terraform completes, add another DNS record to point www.jenom.com to CloudFront:

### DNS Record Details

```
Type:  CNAME
Host:  www
Points to: [YOUR_CLOUDFRONT_DOMAIN].cloudfront.net
TTL:   1 Hour
```

### GoDaddy Instructions

1. **Go back to GoDaddy DNS Management**

2. **Find existing "www" record** (if any):
   - Currently points to: 209.119.246.222 or jenom.com
   - Click "Edit" or "Delete" this record

3. **Update or Add new CNAME**:
   ```
   Type:      CNAME
   Host:      www
   Points to: [YOUR_CLOUDFRONT_DOMAIN].cloudfront.net
   TTL:       1 Hour
   ```

   **Example** (replace with YOUR CloudFront domain):
   ```
   Type:      CNAME
   Host:      www
   Points to: d1a2b3c4d5e6f7.cloudfront.net
   TTL:       1 Hour
   ```

4. **Click "Save"**

---

## Step 5: Upload Website Content

```bash
# Upload your resume HTML
aws s3 cp index.html s3://milestone02-bedrock-website-bucket/ \
  --content-type text/html

# Or run your generate script
cd /Users/captcloud01/Documents/GitHub/redLUIT_Nov2025_AWSBedRockProject02
python scripts/generate_and_deploy.py
```

---

## Step 6: Test Your Website

### Wait for DNS Propagation (5-30 minutes)

```bash
# Check DNS
dig www.jenom.com

# Should show:
# www.jenom.com.    3600    IN    CNAME    d1234567890abc.cloudfront.net.
```

### Test HTTPS Access

```bash
# Test HTTP → HTTPS redirect
curl -I http://www.jenom.com

# Expected: 301 Moved Permanently → https://www.jenom.com/

# Test HTTPS
curl -I https://www.jenom.com

# Expected: HTTP/2 200
```

### Test in Browser

Open: **https://www.jenom.com**

✅ Should load your resume with valid SSL certificate (green lock)

---

## Quick Reference: All DNS Records

After setup, you should have these DNS records in GoDaddy:

| Type | Host | Points To | Purpose |
|------|------|-----------|---------|
| CNAME | `_33e8ad0a9e3f66a234ec5e6f103a48f1.www` | `_c1a81ff1831900d76da8bd3b6cbf5348.jkddzztszm.acm-validations.aws.` | ACM validation |
| CNAME | `www` | `[YOUR_CLOUDFRONT_DOMAIN].cloudfront.net` | Website access |

---

## Certificate Details

```
Domain:          www.jenom.com
Certificate ARN: arn:aws:acm:us-east-1:615299732970:certificate/b3c357ad-2711-42f8-9190-bff6a42fd45a
Region:          us-east-1
Validation:      DNS
Status:          PENDING_VALIDATION → ISSUED (after DNS record added)
```

---

## Troubleshooting

### Certificate Still "PENDING_VALIDATION"

**Check DNS record exists:**
```bash
dig _33e8ad0a9e3f66a234ec5e6f103a48f1.www.jenom.com CNAME
```

**Should return:**
```
_33e8ad0a9e3f66a234ec5e6f103a48f1.www.jenom.com. 3600 IN CNAME _c1a81ff1831900d76da8bd3b6cbf5348.jkddzztszm.acm-validations.aws.
```

**If not found:**
- Verify you added the record correctly in GoDaddy
- Wait for DNS propagation (up to 48 hours, usually < 30 mins)
- Check for typos in the CNAME name/value

### Website Not Loading

**Check CloudFront deployment:**
```bash
cd terraform
terraform output cloudfront_distribution_id

aws cloudfront get-distribution \
  --id [DISTRIBUTION_ID] \
  --query 'Distribution.Status'

# Should return: "Deployed"
```

**Check DNS:**
```bash
dig www.jenom.com

# Should point to CloudFront domain
```

### SSL Certificate Error in Browser

**Verify certificate is attached to CloudFront:**
```bash
aws cloudfront get-distribution \
  --id [DISTRIBUTION_ID] \
  --query 'Distribution.DistributionConfig.ViewerCertificate'

# Should show your certificate ARN
```

---

## Timeline

| Step | Action | Time |
|------|--------|------|
| 1 | Add DNS validation CNAME | 2 minutes |
| 2 | Wait for certificate validation | 5-30 minutes |
| 3 | Deploy Terraform infrastructure | 15-30 minutes |
| 4 | Add website CNAME record | 2 minutes |
| 5 | Wait for DNS propagation | 5-30 minutes |
| 6 | Upload content & test | 5 minutes |
| **Total** | **End-to-end deployment** | **~1 hour** |

---

## Next Steps After Website is Live

1. **Configure CI/CD**: Update GitHub Actions workflows to deploy to www.jenom.com
2. **Enable Monitoring**: Set up CloudWatch alarms for CloudFront metrics
3. **Optional**: Add apex domain (jenom.com) with redirect to www
4. **Optional**: Enable CloudFront logging for analytics
5. **Optional**: Add WAF for additional security

---

## Support

If you need help:
- **Certificate issues**: See CUSTOM_DOMAIN_SETUP.md
- **DNS issues**: See DNS_CONFIGURATION_JENOM.md
- **Deployment issues**: See DEPLOY_JENOM_COM.md

**Remember**: The DNS validation CNAME must be added within 72 hours, or the certificate will fail and you'll need to start over!

---

**Certificate ARN** (save this): `arn:aws:acm:us-east-1:615299732970:certificate/b3c357ad-2711-42f8-9190-bff6a42fd45a`

**Next**: Add the DNS validation CNAME to GoDaddy NOW, then wait for "ISSUED" status before deploying!
