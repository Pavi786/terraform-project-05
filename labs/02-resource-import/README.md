# Lab 02 – Importing Existing AWS Resources

## 1. Real-World Production Incident
**Incident Ticket #INC-1022:**  
*Summary:* An infrastructure component (an SQS dead-letter queue) was provisioned manually via AWS Console during a production hotfix. The team now requires all cloud infrastructure to be 100% managed under Terraform. We must bring the existing queue into Terraform state **without destroying or recreating it**, as active messages are in flight.

---

## 2. Concept & Methods
Terraform offers two approaches to importing:
1. **Modern Declarative `import` block (Terraform 1.5+):** Code-first, reviewable in pull requests, generates template code.
2. **Traditional CLI `terraform import`:** Imperative command updating state directly.

### Modern Import Block (Recommended)
```hcl
import {
  to = aws_sqs_queue.orders_dlq
  id = "https://sqs.ap-southeast-1.amazonaws.com/352458843311/p05-unmanaged-orders-dlq"
}

resource "aws_sqs_queue" "orders_dlq" {
  name                      = "p05-unmanaged-orders-dlq"
  message_retention_seconds = 86400
}
```

---

## 3. Terminal Execution Sequence
1. Create target SQS queue in AWS Console or via AWS CLI.
2. Add the `import` block and matching `resource` block.
3. Run `terraform plan`:
   *Expected:* `Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.`
4. Run `terraform apply`:
   Imports the resource directly into S3 remote state.
