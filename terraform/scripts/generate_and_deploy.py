#!/usr/bin/env python3
"""
Generate and deploy resume using AWS Bedrock
"""
import argparse
import json
import boto3
from pathlib import Path


def call_bedrock_generate_html(resume_md, model_id=None):
    """
    Call AWS Bedrock to generate HTML from markdown resume.
    Uses bedrock-runtime client for model invocation.
    
    Args:
        resume_md: Markdown content of the resume
        model_id: Optional model ID to use. If None, tries multiple options.
    """
    client = boto3.client("bedrock-runtime")

    # List of model IDs to try (in order of preference)
    # Using cross-region inference profiles for on-demand throughput
    model_ids = [
        # Cross-region inference profiles (recommended for on-demand)
        "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
        "us.anthropic.claude-3-5-sonnet-20240620-v1:0",
        
        # Standard model IDs (may not work with on-demand in all regions)
        "anthropic.claude-3-5-sonnet-20240620-v1:0",
        "anthropic.claude-3-sonnet-20240229-v1:0",
        
        # Haiku as fallback (faster, cheaper)
        "us.anthropic.claude-3-5-haiku-20241022-v1:0",
        "anthropic.claude-3-5-haiku-20241022-v1:0",
    ]
    
    # If a specific model was requested, try it first
    if model_id:
        model_ids.insert(0, model_id)

    # Prepare the prompt
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

    # Prepare the request body for Claude model
    body = json.dumps(
        {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "messages": [
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
        }
    )

    # Try each model ID until one works
    last_error = None
    for try_model_id in model_ids:
        try:
            print(f"🤖 Attempting to use model: {try_model_id}")
            
            response = client.invoke_model(
                modelId=try_model_id,
                contentType="application/json",
                accept="application/json",
                body=body,
            )

            # Parse the response
            response_body = json.loads(response["body"].read())
            html_content = response_body["content"][0]["text"]

            print(f"✅ Successfully used model: {try_model_id}")
            return html_content

        except client.exceptions.ValidationException as e:
            error_msg = str(e)
            print(f"⚠️ Model {try_model_id} failed: {error_msg}")
            last_error = e
            
            # If it's about inference profiles, continue to next model
            if "inference profile" in error_msg.lower() or "on-demand throughput" in error_msg.lower():
                print(f"   → Trying next model...")
                continue
            # If it's model access, might need to request access
            elif "access" in error_msg.lower():
                print(f"   ℹ️ You may need to request access to this model in AWS Console")
                continue
            else:
                # For other validation errors, might be worth trying next model
                continue
                
        except client.exceptions.ModelNotReadyException as e:
            print(f"⚠️ Model {try_model_id} not ready: {e}")
            last_error = e
            continue
            
        except client.exceptions.ThrottlingException as e:
            print(f"⚠️ Throttling on {try_model_id}: {e}")
            last_error = e
            continue
            
        except Exception as e:
            print(f"⚠️ Unexpected error with {try_model_id}: {e}")
            last_error = e
            continue

    # If we get here, all models failed
    print(f"\n❌ All models failed. Last error: {last_error}")
    print(f"\n💡 Troubleshooting tips:")
    print(f"   1. Check model access in AWS Console → Bedrock → Model access")
    print(f"   2. Ensure your region supports these models")
    print(f"   3. Try requesting access to Claude models")
    print(f"   4. Check AWS credentials have bedrock:InvokeModel permission")
    raise last_error


def upload_to_s3(html_content, bucket_name, env="prod"):
    """
    Upload generated HTML to S3 bucket.
    """
    s3 = boto3.client("s3")

    # Determine object key based on environment
    object_key = "index.html" if env == "prod" else f"{env}/index.html"

    try:
        print(f"📤 Uploading to s3://{bucket_name}/{object_key}")

        s3.put_object(
            Bucket=bucket_name,
            Key=object_key,
            Body=html_content.encode("utf-8"),
            ContentType="text/html",
        )

        print(f"✅ Successfully uploaded to S3: {object_key}")

        # Generate URL
        region = s3.get_bucket_location(Bucket=bucket_name)[
            "LocationConstraint"
        ]
        if region is None:
            region = "us-east-1"

        url = f"https://{bucket_name}.s3.{region}.amazonaws.com/{object_key}"
        print(f"🌐 Resume URL: {url}")

        return url

    except s3.exceptions.NoSuchBucket:
        print(f"❌ Bucket {bucket_name} does not exist")
        raise
    except Exception as e:
        print(f"❌ Error uploading to S3: {e}")
        raise


def main():
    """Main function to orchestrate resume generation and deployment."""
    parser = argparse.ArgumentParser(
        description="Generate and deploy AI-powered resume"
    )
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
        help="Specific Bedrock model ID to use (optional)",
    )

    args = parser.parse_args()

    print(f"🚀 Starting resume generation and deployment")
    print(f"📝 Environment: {args.env}")
    print(f"🪣 Bucket: {args.bucket}")

    # Read the markdown resume template
    template_path = Path(args.template)
    if not template_path.exists():
        print(f"❌ Template file not found: {args.template}")
        return 1

    print(f"📖 Reading template from: {args.template}")
    with open(template_path, "r", encoding="utf-8") as f:
        resume_md = f.read()

    print(f"✅ Loaded resume template ({len(resume_md)} characters)")

    # Generate HTML using Bedrock
    print("🤖 Calling AWS Bedrock to generate HTML...")
    html = call_bedrock_generate_html(resume_md, args.model_id)
    print(f"✅ Generated HTML ({len(html)} characters)")

    # Upload to S3
    print("☁️ Uploading to S3...")
    url = upload_to_s3(html, args.bucket, args.env)

    print("🎉 Deployment complete!")
    print(f"🌐 Your resume is live at: {url}")

    return 0


if __name__ == "__main__":
    exit(main())