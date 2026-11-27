# Lab 04 – Terraform State Backup & Disaster Recovery

## 1. Real-World Production Incident
**Incident Ticket #INC-3109:**  
*Summary:* A CI/CD pipeline job failed midway through a state migration, or an engineer corrupted the remote state file. Terraform now throws parse errors or reports that all production resources no longer exist.

---

## 2. Disaster Recovery Checklist
1. **Never panic and never run `terraform apply`** on an empty state (it will recreate duplicate resources or orphan live infrastructure).
2. Leverage S3 Bucket Versioning:
   ```bash
   aws s3api list-object-versions \
     --bucket <STATE_BUCKET> \
     --prefix environments/dev/terraform.tfstate \
     --region ap-southeast-1
   ```
3. Download the last known good version:
   ```bash
   aws s3api get-object \
     --bucket <STATE_BUCKET> \
     --key environments/dev/terraform.tfstate \
     --version-id "<LAST_KNOWN_GOOD_VERSION_ID>" \
     recovered_state.json
   ```
4. Verify Lineage & Serial:
   Every state file has a `lineage` GUID and an incrementing integer `serial`.
5. Restore using `terraform state push`:
   ```bash
   terraform state push recovered_state.json
   ```
