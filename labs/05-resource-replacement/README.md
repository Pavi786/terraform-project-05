# Lab 05 – Safe EC2 Resource Replacement

## 1. Real-World Production Incident
**Incident Ticket #INC-4420:**  
*Summary:* An EC2 instance has an unhealthy OS filesystem corruption or compromised kernel, but its Terraform configuration hasn't changed. Running `terraform apply` reports `No changes`. How do we force a controlled, safe recreation without modifying `.tf` code?

---

## 2. Command: `terraform apply -replace`
Instead of the deprecated `terraform taint`, modern Terraform uses:

```bash
terraform plan -replace="module.ec2.aws_instance.this" -out=replace_plan.tfplan
```

*Expected Output:*
```text
Terraform will perform the following actions:

  # module.ec2.aws_instance.this will be replaced, as requested
-/+ resource "aws_instance" "this" {
      ~ id = "i-old12345" -> (known after apply)
      ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

Applying the saved plan:
```bash
terraform apply replace_plan.tfplan
```
---

## 3. Minimizing Downtime: `create_before_destroy`
In lifecycle configuration:
```hcl
lifecycle {
  create_before_destroy = true
}
```
Terraform launches the new healthy instance **first**, waits for AWS confirmation, and only then terminates the old instance.
