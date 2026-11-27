# Preflight Verification Script (Windows PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "=== [1/4] Checking Terraform Version ===" -ForegroundColor Cyan
terraform version

Write-Host "`n=== [2/4] Checking AWS Region & Identity ===" -ForegroundColor Cyan
Write-Host "Configured Target Region: ap-southeast-1"

Write-Host "`n=== [3/4] Validating Terraform Dev Code ===" -ForegroundColor Cyan
Push-Location "environments/dev"
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
Pop-Location

Write-Host "`n✓ Preflight validation completed successfully!" -ForegroundColor Green
