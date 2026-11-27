# Terraform Production Troubleshooting Guide

| Issue / Error | Root Cause | Solution |
|---|---|---|
| `Error: Error acquiring the state lock` | A previous apply crashed or another engineer is running `apply`. | Verify no pipeline is running, then run `terraform force-unlock <LOCK_ID>`. |
| `Resource already exists` during apply | Resource was created manually outside Terraform. | Import the resource using an `import {}` block or delete the manual resource. |
| `Plan proposes destroy and recreate` | An argument that does not support in-place update was modified (e.g., changing VPC ID or subnet). | Check if change is intended or use `create_before_destroy = true` to minimize downtime. |
| `Error: Provider configuration not present` | A module uses a provider alias that wasn't passed down. | Add `configuration_aliases` to module `versions.tf` and pass the alias from root. |
