# Senior DevOps Interview Questions & Expert Answers: Terraform Operations

### Q1: How do you detect and remediate infrastructure drift in automated CI/CD pipelines?
**Answer:** In production CI/CD, we schedule a daily or hourly pipeline running `terraform plan -refresh-only -detailed-exitcode`. If exit code is `2`, drift is present, triggering a Slack/email alert to the platform team. For non-production, an automated pipeline can re-apply the approved code. In production, an engineer reviews the diff to verify whether the drift was an emergency authorized hotfix or an unauthorized manual change.

### Q2: What is the difference between `terraform state mv` and a `moved` block?
**Answer:** `terraform state mv` is an imperative CLI command that modifies the state file immediately on the local machine. It is risky in team environments because other engineers don't have the move recorded in Git. `moved` blocks (introduced in Terraform 1.1) are declarative code tracked in Git. When any engineer or CI runner pulls the branch, Terraform automatically executes the state move during `terraform plan` without destroying resources.

### Q3: When should you use `use_lockfile = true` vs DynamoDB for S3 backend locking?
**Answer:** Starting in Terraform 1.10+, `use_lockfile = true` utilizes Amazon S3's native conditional write capabilities to enforce locking directly within the S3 bucket. This eliminates the operational overhead, IAM permissions, and cost of maintaining a separate DynamoDB table.

### Q4: What are the risks of `terraform state push`?
**Answer:** `terraform state push` forcefully overwrites the remote state in S3. If pushed with an older serial or incorrect lineage, it can desynchronize Terraform from the real infrastructure, causing subsequent applies to recreate or orphan production resources. Always back up the existing state and verify the lineage and serial number beforehand.
