#!/usr/bin/env python3
"""
Helper script to detect and optionally unlock stale Terraform state locks
in a DynamoDB lock table used by S3 backend + DynamoDB locking.

Usage:
  python tf_unlock_stale.py \
      --table YOUR_DYNAMO_LOCK_TABLE_NAME \
      --age 30  # minutes threshold to consider lock stale
      [--auto-unlock]  # if provided, delete stale lock entries
"""

import argparse
import boto3
import datetime
import time

def iso_to_dt(s: str):
    # Example timestamp format in DynamoDB "Created": "2025-11-27 21:45:08.391889026 +0000 UTC"
    # Adjust parsing if needed depending on actual format
    try:
        # Trim timezone for simplicity, convert to naive UTC
        parts = s.split(" +")[0]
        return datetime.datetime.fromisoformat(parts)
    except Exception:
        return None

def find_stale_locks(table_name, age_minutes, region=None):
    client = boto3.client("dynamodb", region_name=region)
    paginator = client.get_paginator("scan")
    now = datetime.datetime.utcnow()
    stale = []
    for page in paginator.paginate(TableName=table_name):
        for item in page.get("Items", []):
            lock_id = item.get("LockID", {}).get("S")
            info = item.get("Info", {}).get("M")
            if info:
                created = info.get("Created", {}).get("S")
                podt = iso_to_dt(created) if created else None
                if podt:
                    age = now - podt
                    if age > datetime.timedelta(minutes=age_minutes):
                        stale.append({
                            "LockID": lock_id,
                            "Created": created,
                            "Age (min)": int(age.total_seconds() / 60),
                        })
    return stale

def delete_lock(table_name, lock_id, region=None):
    client = boto3.client("dynamodb", region_name=region)
    resp = client.delete_item(
        TableName=table_name,
        Key={"LockID": {"S": lock_id}}
    )
    return resp

def main():
    parser = argparse.ArgumentParser(description="Detect and (optionally) remove stale Terraform DynamoDB locks.")
    parser.add_argument("--table", required=True, help="Name of the DynamoDB lock table")
    parser.add_argument("--age", type=int, default=30, help="Age in minutes to consider a lock stale")
    parser.add_argument("--region", default=None, help="AWS region (optional)")
    parser.add_argument("--auto-unlock", action="store_true", help="Delete stale locks automatically")
    args = parser.parse_args()

    stale = find_stale_locks(args.table, args.age, region=args.region)
    if not stale:
        print("✅ No stale locks older than", args.age, "minutes found.")
        return 0

    print("⚠️ Found stale locks:")
    for lock in stale:
        print("  LockID:", lock["LockID"], "Created:", lock["Created"], "Age (min):", lock["Age (min)"])

    if args.auto_unlock:
        for lock in stale:
            print("🔓 Deleting lock:", lock["LockID"])
            delete_lock(args.table, lock["LockID"], region=args.region)
        print("✅ Deleted", len(stale), "stale locks.")
    else:
        print("ℹ️ Run again with --auto-unlock to delete these stale locks.")

if __name__ == "__main__":
    main()