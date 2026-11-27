# Incident Runbooks (Quick Reference)

### Incident 1: Unexpected Security Group Rule Added Manually
- **Step 1:** Run `terraform plan -refresh-only` to observe the drift.
- **Step 2:** If rogue/unauthorized, run `terraform apply` to strip the unauthorized rule and restore the approved code.
- **Step 3:** If authorized, update `.tf` file to include the rule and run `terraform apply -refresh-only`.

### Incident 2: Unmanaged SQS Queue Needs Terraform Ownership
- **Step 1:** Identify queue URL: `https://sqs.ap-southeast-1.amazonaws.com/<ACCOUNT>/<QUEUE_NAME>`.
- **Step 2:** Write `import { to = aws_sqs_queue.name id = "<QUEUE_URL>" }`.
- **Step 3:** Write the matching `resource "aws_sqs_queue"` block.
- **Step 4:** Run `terraform plan` (Verify `1 to import, 0 to add, 0 to destroy`).
- **Step 5:** Run `terraform apply`.

### Incident 3: Refactoring Resource into a Child Module
- **Step 1:** Do **NOT** delete the old block or run apply.
- **Step 2:** Add `moved { from = aws_instance.web to = module.ec2.aws_instance.this }`.
- **Step 3:** Run `terraform plan` (Verify `0 to add, 0 to change, 0 to destroy`).
- **Step 4:** Commit to Git and apply cleanly.

### Incident 4: Corrupted or Lost State File
- **Step 1:** Immediately stop all CI/CD pipelines.
- **Step 2:** Inspect S3 bucket versioning for `environments/dev/terraform.tfstate`.
- **Step 3:** Download last known healthy version via AWS CLI.
- **Step 4:** Run `terraform state push <RECOVERED_FILE>`.
- **Step 5:** Run `terraform plan` to verify state matches live cloud.

### Incident 5: Corrupted EC2 Instance Needing Clean Recreate
- **Step 1:** Run `terraform plan -replace="module.ec2.aws_instance.this" -out=replace.tfplan`.
- **Step 2:** Verify only 1 replacement is planned.
- **Step 3:** Run `terraform apply replace.tfplan`.
