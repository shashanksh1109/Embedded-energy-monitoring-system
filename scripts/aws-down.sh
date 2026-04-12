#!/bin/bash
# aws-down.sh — Destroy all AWS resources
# Usage: ./scripts/aws-down.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REGION="us-east-1"
ACCOUNT_ID="993268716712"

echo ""
echo "================================================================"
echo "  ENERGY MANAGEMENT SYSTEM — AWS SHUTDOWN"
echo "================================================================"
echo ""
echo "  This will destroy all AWS resources."
echo "  RDS will save a final snapshot before deletion."
echo "  Cost after destroy: \$0.00/hour"
echo ""
read -p "  Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then
  echo "  Aborted."
  exit 0
fi

# ─── Empty S3 buckets ────────────────────────────────────────────────
echo ""
echo "[1/4] Emptying S3 buckets..."
aws s3 rm s3://energy-management-frontend-$ACCOUNT_ID/ \
  --recursive --region $REGION 2>/dev/null || true
echo "  ✓ S3 buckets emptied"

# ─── Delete ECR images ───────────────────────────────────────────────
echo ""
echo "[2/4] Deleting ECR images..."
for repo in backend gateway sensor hvac power; do
  IMAGES=$(aws ecr list-images \
    --region $REGION \
    --repository-name energy-management/$repo \
    --query 'imageIds[*]' \
    --output json 2>/dev/null || echo "[]")
  if [ "$IMAGES" != "[]" ] && [ "$IMAGES" != "" ]; then
    aws ecr batch-delete-image \
      --region $REGION \
      --repository-name energy-management/$repo \
      --image-ids "$IMAGES" > /dev/null 2>&1 || true
  fi
done
echo "  ✓ ECR images deleted"

# ─── Delete old RDS snapshot if exists ───────────────────────────────
echo ""
echo "[3/4] Checking for existing RDS snapshot..."
EXISTING=$(aws rds describe-db-snapshots \
  --region $REGION \
  --db-snapshot-identifier energy-management-final-snapshot \
  --query "DBSnapshots[0].DBSnapshotIdentifier" \
  --output text 2>/dev/null || echo "none")

if [ "$EXISTING" = "energy-management-final-snapshot" ]; then
  echo "  Found existing snapshot — deleting before destroy..."
  aws rds delete-db-snapshot \
    --region $REGION \
    --db-snapshot-identifier energy-management-final-snapshot
  echo "  Waiting for deletion..."
  aws rds wait db-snapshot-deleted \
    --region $REGION \
    --db-snapshot-identifier energy-management-final-snapshot
  echo "  ✓ Old snapshot deleted"
else
  echo "  No existing snapshot found"
fi

# ─── Terraform destroy ───────────────────────────────────────────────
echo ""
echo "[4/4] Destroying infrastructure..."
cd "$PROJECT_DIR/Terraform"
terraform destroy -auto-approve

echo ""
echo "================================================================"
echo "  SYSTEM IS DOWN"
echo "================================================================"
echo ""
echo "  All AWS resources destroyed."
echo "  Cost: \$0.00/hour"
echo ""
echo "  To bring back up: ./scripts/aws-up.sh"
echo ""
