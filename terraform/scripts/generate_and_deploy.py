#!/usr/bin/env python3
"""
Generate and deploy resume using AWS Bedrock (with inference‑profile fallback)
"""
import argparse
import json
import boto3
import botocore
from pathlib import Path

def find_inference_profile_for_model(mgmt_client, foundation_model_id_prefix, max_results=50):
    """
    Return an inference‑profile ID/ARN whose model matches the given foundation‑model prefix.
    If none found, return None.
    """
    try:
        resp = mgmt_client.list_inference_profiles(
            typeEquals="SYSTEM_DEFINED",
            maxResults=max_results
        )
    except botocore.exceptions.ClientError as e:
        print("⚠️ Error listing inference profiles:", e)
        return None

    for prof in resp.get("inferenceProfileSummaries", []):
        # Try multiple identifiers
        pid = prof.get("inferenceProfileArn") or prof.get("inferenceProfileId") or prof.get("inferenceProfileName")
        if not pid:
            continue
        # Each profile has `"models"` list — check modelArn inside
        for m in prof.get("models", []):
            model_arn = m.get("modelArn", "")
            if foundation_model_id_prefix in model_arn:
                return pid
    return None

def call_bedrock_generate_html(resume_md, model_id=None, region_name=None):
    """
    Call Amazon Bedrock to generate HTML from markdown resume.
    Tries foundation‑model IDs first; on failure due to throughput restrictions,
    attempts to locate and use an inference profile.
    """
    runtime = boto3.client("bedrock-runtime", region_name=region_name)
    mgmt = boto3.client("bedrock", region_name=region_name)

    base_model_ids = [
        "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
        "us.anthropic.claude-3-5-sonnet-20240620-v1:0",
        "anthropic.claude-3-5-sonnet-20240620-v1:0",
        "anthropic.claude-3-sonnet-20240229-v1:0",
        "us.anthropic.claude-3-5-haiku-20241022-v1:0",
        "anthropic.claude-3-5-haiku-20241022-v1:0",
    ]

    attempts = []
    if model_id:
        attempts.append(model_id)
    attempts.extend(base_model_ids)

    prompt = f"""Convert the following markdown resume into a beautiful, 
professional HTML page with CSS styling. Use modern design principles, 
good typography, and make it mobile-responsive.

Include:
- A clean, professional layout
- Proper heading hierarchy
- Good use of whitespace
- Mobile-responsive design
- Professional color scheme
- Easy-to-read fonts

Markdown Resume:
{resume_md}

Generate a complete, standalone HTML document with embedded CSS. 
Do not include any explanatory text, just output the HTML."""

    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,
        "messages": [
            {
                "role": "user",
                "content": prompt,
            }
        ],
    })

    last_error = None
    for try_model in attempts:
        try:
            print("🤖 Attempting foundation model id:", try_model)
            response = runtime.invoke_model(
                modelId=try_model,
                contentType="application/json",
                accept="application/json",
                body=body,
            )
            resp_body = json.loads(response["body"].read())
            html_content = resp_body["content"][0]["text"]
            print("✅ Successfully used foundation model:", try_model)
            return html_content

        except Exception as e:
            err = str(e)
            print("⚠️ Foundation model invocation failed:", err)
            lower = err.lower()

            # If failure indicates on‑demand throughput / need inference profile
            if "on-demand throughput" in lower or "inference profile" in lower:
                print("   ℹ️ Attempting to find inference profile for:", try_model)
                prefix = try_model.split(":")[0]
                profile = find_inference_profile_for_model(mgmt, prefix)
                if profile:
                    print("   ✅ Found inference profile:", profile)
                    try:
                        response = runtime.invoke_model(
                            modelId=profile,
                            contentType="application/json",
                            accept="application/json",
                            body=body,
                        )
                        resp_body = json.loads(response["body"].read())
                        html_content = resp_body["content"][0]["text"]
                        print("✅ Successfully used inference profile:", profile)
                        return html_content
                    except Exception as e2:
                        print("⚠️ Inference profile invocation failed:", e2)
                        last_error = e2
                        continue
                else:
                    print("   ✖️ No matching inference profile found.")
            last_error = e
            continue

    print("\n❌ All models / profiles failed. Last error:", last_error)
    print("\n💡 Troubleshooting tips:")
    print("   1. Ensure your AWS account has model access in Bedrock → Model access.")
    print("   2. Confirm inference profiles exist (system‑defined or application) and include desired model.")
    print("   3. Check IAM permissions include bedrock:InvokeModel and bedrock:ListInferenceProfiles.")
    print("   4. Ensure region_name matches a supported region for the model or inference profile.")
    raise last_error

def upload_to_s3(html_content, bucket_name, env="prod"):
    s3 = boto3.client("s3")
    object_key = "index.html" if env == "prod" else f"{env}/index.html"

    print(f"📤 Uploading to s3://{bucket_name}/{object_key}")
    s3.put_object(
        Bucket=bucket_name,
        Key=object_key,
        Body=html_content.encode("utf-8"),
        ContentType="text/html",
    )
    print("✅ Successfully uploaded to S3.")

    region = s3.get_bucket_location(Bucket=bucket_name).get("LocationConstraint")
    if not region:
        region = "us-east-1"
    url = f"https://{bucket_name}.s3.{region}.amazonaws.com/{object_key}"
    print("🌐 Resume URL:", url)
    return url

def main():
    parser = argparse.ArgumentParser(description="Generate and deploy AI-powered resume")
    parser.add_argument(
        "--env",
        default="prod",
        choices=["prod", "beta", "dev"],
        help="Deployment environment",
    )
    parser.add_argument(
        "--bucket", required=True, help="S3 bucket name for deployment"
    )
    parser.add_argument(
        "--template",
        default="resume_template.md",
        help="Path to markdown resume template",
    )
    parser.add_argument(
        "--model-id",
        default=None,
        help="Specific Bedrock model ID or inference profile ID to use (optional)",
    )
    parser.add_argument(
        "--region",
        default=None,
        help="AWS region (optional, e.g. us-east-1)",
    )

    args = parser.parse_args()

    print("🚀 Starting resume generation and deployment")
    print("📝 Environment:", args.env)
    print("🪣 Bucket:", args.bucket)

    template_path = Path(args.template)
    if not template_path.exists():
        print("❌ Template file not found:", args.template)
        return 1

    with open(template_path, "r", encoding="utf-8") as f:
        resume_md = f.read()

    print(f"✅ Loaded resume template ({len(resume_md)} chars)")

    print("🤖 Calling Amazon Bedrock to generate HTML...")
    html = call_bedrock_generate_html(resume_md, model_id=args.model_id, region_name=args.region)
    print(f"✅ Generated HTML (length: {len(html)} chars)")

    print("☁️ Uploading to S3...")
    upload_to_s3(html, args.bucket, args.env)

    print("🎉 Deployment complete!")
    return 0

if __name__ == "__main__":
    exit(main())