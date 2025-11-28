#!/usr/bin/env bash
# clean_tf_lock_table.sh — scan + delete items in a DynamoDB lock table
# WARNING: Use only if you are sure no active Terraform run holds the lock.

set -euo pipefail

TABLE_NAME="${1:-dyning_table}"
REGION="${2:-us-east-1}"
DRY_RUN="${DRY_RUN:-false}"  # If DRY_RUN=true, we only list locks. To delete, set DRY_RUN=false.

if [[ -z "$TABLE_NAME" ]]; then
  echo "Usage: $0 <dynamodb-lock-table-name> [aws-region] [dry-run:true|false]"
  echo "Example: $0 terraform-locks us-east-1 false"
  exit 1
fi

echo "Scanning DynamoDB table '$TABLE_NAME' in region '$REGION'..."
LOCK_IDS=$(aws dynamodb scan \
  --table-name "$TABLE_NAME" \
  --region "$REGION" \
  --query "Items[].LockID.S" \
  --output text)

if [[ -z "$LOCK_IDS" ]]; then
  echo "✅ No lock entries found in table '$TABLE_NAME'."
  exit 0
fi

echo "Found lock IDs:"
echo "$LOCK_IDS" | tr '\t' '\n'

if [[ "${DRY_RUN,,}" == "true" ]]; then
  echo "Dry‑run: not deleting any items. To delete, re‑run with DRY_RUN=false environment variable."
  exit 0
fi

echo "Deleting lock entries..."
for lock_id in $LOCK_IDS; do
  echo "  → Deleting lock ID: $lock_id"
  aws dynamodb delete-item \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --key "{\"LockID\": {\"S\": \"$lock_id\"}}"
done

echo "✅ Deleted all lock entries from '$TABLE_NAME'."