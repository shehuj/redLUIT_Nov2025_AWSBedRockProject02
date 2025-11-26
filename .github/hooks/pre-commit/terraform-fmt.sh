#!/usr/bin/env bash
# Run terraform fmt before commit — skip if no .tf files changed

# Find any .tf or .tfvars files in staged changes
if git diff --cached --name-only | grep -E '\.tf(var)?$' >/dev/null; then
  echo "Running terraform fmt..."
  terraform fmt -recursive
  # Add any changes made by fmt to staging
  git add .
fi

# Continue with commit
exit 0