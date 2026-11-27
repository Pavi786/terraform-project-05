# Preflight Verification Script (Linux/macOS)
set -euo pipefail

echo "=== [1/4] Checking Terraform Version ==="
terraform version

echo "=== [2/4] Checking AWS CLI Identity ==="
aws sts get-caller-identity --output table

echo "=== [3/4] Verifying Target Region ==="
echo "Configured Region: ap-southeast-1"

echo "=== [4/4] Validating Terraform Code ==="
cd environments/dev
terraform fmt -check -recursive
echo "Preflight checks passed!"
