import argparse
import boto3
import os

def read_resume_template():
    with open("resume_template.md", "r") as f:
        return f.read()
    
def call_bedrock_generate_html(resume_md):
    client = boto3.client("bedrock")
    response = client.invoke_model(
        modelId="anthropic.claude-v2",
        contentType="text/markdown",
        accept="text/html",
        body=resume_md.encode("utf-8"),
    )
    html = response["body"].read().decode("utf-8")
    return html

def call_bedrock_ats_analysis(html):
    client = boto3.client("bedrock")
    prompt = (
        "Analyze the following resume HTML for ATS compatibility metrics and return JSON:\n\n" + html
    )
    response = client.invoke_model(
        modelId="anthropic.claude-v2",
        contentType="text/html",
        accept="application/json",
        body=prompt.encode("utf-8"),
    )
    analysis_json = response["body"].read().decode("utf-8")
    return analysis_json

def upload_html_to_s3(html, bucket, key):
    s3 = boto3.client("s3")
    s3.put_object(Bucket=bucket, Key=key, Body=html, ContentType="text/html")

def write_metadata_to_dynamodb(env, bucket, key, analysis_json):
    dynamodb = boto3.resource("dynamodb")
    table_name = f"ResumeDeployMetadata-{env}"
    table = dynamodb.Table(table_name)
    item = {
        "ResumeKey": key,
        "Bucket": bucket,
        "Env": env,
        "ATSAnalysis": analysis_json,
    }
    table.put_item(Item=item)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--env", required=True, help="Deployment environment")
    parser.add_argument("--bucket", required=True, help="S3 bucket to upload HTML")
    args = parser.parse_args()

    resume_md = read_resume_template()
    html = call_bedrock_generate_html(resume_md)
    analysis_json = call_bedrock_ats_analysis(html)
    key = f"{args.env}/resume.html"
    upload_html_to_s3(html, args.bucket, key)
    write_metadata_to_dynamodb(args.env, args.bucket, key, analysis_json)
    print(f"Resume deployed to s3://{args.bucket}/{key} with ATS analysis stored in DynamoDB.")

if __name__ == "__main__":
    main()
