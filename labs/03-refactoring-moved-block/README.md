# Lab 03 – Refactoring with Moved Blocks

## 1. Real-World Production Incident
**Incident Ticket #INC-2045:**  
*Summary:* A monolithic Terraform configuration defined `aws_instance.web`. The team is standardizing on a reusable `modules/ec2` module. Simply changing the code address from `aws_instance.web` to `module.ec2.aws_instance.this` would normally cause Terraform to **destroy the production server and create a brand new one** (causing downtime and data loss).

---

## 2. Solution: The Declarative `moved` Block (Terraform 1.1+)
Instead of manual, risky `terraform state mv` commands run out-of-band by developers, Terraform allows declarative `moved` blocks tracked in Git:

```hcl
moved {
  from = aws_instance.web
  to   = module.ec2.aws_instance.this
}
```

When you run `terraform plan`:
```text
Terraform will perform the following actions:

  # aws_instance.web has moved to module.ec2.aws_instance.this
    resource "aws_instance" "this" {
        id = "i-0123456789abcdef0"
        # (all attributes preserved)
    }

Plan: 0 to add, 0 to change, 0 to destroy.
```
**Zero downtime. Zero recreation. The EC2 instance ID stays exactly the same!**
