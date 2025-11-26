#!/usr/bin/env python3
"""
Generate and deploy resume using AWS Bedrock
"""
import argparse
import json
import boto3
from pathlib import Path


def call_bedrock_generate_html(resume_md):
    """
    Call AWS Bedrock to generate HTML from markdown resume.
    Uses bedrock-runtime client for model invocation.
    """
    # IMPORTANT: Use 'bedrock-runtime' not 'bedrock' for invoke_model
    client = boto3.client("bedrock-runtime")

    # Prepare the prompt
    prompt = f"""Convert the following markdown resume into a beautiful, 
professional HTML page with CSS styling. Use modern design principles, 
good typography, and make it mobile-responsive.

Markdown Resume:
{resume_md}

Generate a complete HTML document with embedded CSS."""

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

    try:
        # Invoke the model using bedrock-runtime
        response = client.invoke_model(
            modelId="anthropic.claude-3-5-sonnet-20241022-v2:0",
            contentType="application/json",
            accept="application/json",
            body=body,
        )

        # Parse the response
        response_body = json.loads(response["body"].read())
        html_content = response_body["content"][0]["text"]

        return html_content

    except client.exceptions.ValidationException as e:
        print(f"❌ Validation Error: {e}")
        raise
    except client.exceptions.ModelNotReadyException as e:
        print(f"❌ Model Not Ready: {e}")
        raise
    except client.exceptions.ThrottlingException as e:
        print(f"⚠️ Throttling: {e}")
        raise
    except Exception as e:
        print(f"❌ Unexpected error calling Bedrock: {e}")
        raise


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
    html = call_bedrock_generate_html(resume_md)
    print(f"✅ Generated HTML ({len(html)} characters)")

    # Upload to S3
    print("☁️ Uploading to S3...")
    url = upload_to_s3(html, args.bucket, args.env)

    print("🎉 Deployment complete!")
    print(f"🌐 Your resume is live at: {url}")

    return 0


if __name__ == "__main__":
    exit(main())