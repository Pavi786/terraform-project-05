# Resource Verification Script (Linux/macOS)
set -euo pipefail
REGION="ap-southeast-1"

echo "=== Checking Security Groups in $REGION ==="
aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters "Name=tag:Lab,Values=terraform-project-05" \
  --query "SecurityGroups[*].{ID:GroupId,Name:GroupName,VpcId:VpcId}" \
  --output table

echo "=== Checking S3 State Buckets in $REGION ==="
aws s3api list-buckets \
  --query "Buckets[?contains(Name, 'p05-tfstate')].Name" \
  --output table
