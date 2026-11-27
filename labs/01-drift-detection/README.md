# Lab 01 – Infrastructure Drift Detection & Remediation

## 1. Real-World Production Incident
**Incident Ticket #INC-9481:**  
*Severity:* P1 - Security Compliance Violation  
*Summary:* An on-call engineer troubleshooting an off-hours connectivity alert manually opened inbound rules directly inside the AWS Console. Two days later, an automated security audit flagged that an internal database/application port was left wide open to unapproved CIDRs. When a colleague attempted to run a planned Terraform release, unexpected drift was detected.

---

## 2. Architecture & Concept
```text
  [Approved IaC Code]               [Terraform State]               [Real AWS World]
   (environments/dev)             (S3 Remote Backend)              (ap-southeast-1)
           │                               │                              │
           │                               │                              │
    Port 443 only                   Port 443 only               Manual Console Edit:
   (from 10.0.0.0/16)              (from 10.0.0.0/16)          [Port 443 from 10.0.0.0/16]
           │                               │           + [Unapproved Port 8080/443]
           │                               │                              │
           └───────────────────────────────┼──────────────────────────────┘
                                           │
                                           ▼
                             `terraform plan -refresh-only`
                                  (Detects the Drift)
```

---

## 3. Layman Explanation
Imagine a company's building blueprint (Terraform code). The building manager keeps a copy of the blueprint in the archive (State file). One weekend, a maintenance worker punches a hole in the wall to run a temporary cable, but forgets to tell anyone.  
- **Drift** is the difference between the blueprint and the actual building.  
- `terraform plan -refresh-only` is like sending an inspector with a clipboard to look at the physical building and compare it with the state file without touching or demolishing anything.  
- If you run `terraform apply`, Terraform repairs the wall back to blueprint specifications.  
- If you run `terraform apply -refresh-only`, Terraform updates the blueprint to say "the hole is officially accepted".

---

## 4. Terraform Code Walkthrough
File: [`environments/dev/main.tf`](../../environments/dev/main.tf)
```hcl
resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}-app-sg"
  description = "Managed Security Group for Lab 01 - Drift Detection"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTPS from internal test CIDR only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_test_cidr] # Default: 10.0.0.0/16
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
*Why this design?*
- Restricts ingress to port 443 from internal CIDR (`10.0.0.0/16`).
- Does **not** open SSH (Port 22) or `0.0.0.0/0` inbound.
- Controlled test target that can be safely modified manually in the console to practice drift.

---

## 5. Exact Terminal Commands & Execution Sequence

### Phase A: Deploy the Baseline Infrastructure
```bash
cd environments/dev
terraform init
terraform plan -out=tfplan
# [Review Plan with Mentor before running apply]
terraform apply tfplan
```

### Phase B: Simulate the Incident (Manual Out-of-band Change)
1. Open the **AWS Console > VPC > Security Groups** in `ap-southeast-1`.
2. Find the Security Group: `p05-incident-mgmt-dev-app-sg`.
3. Click **Edit inbound rules**.
4. Add a rule:
   - Type: `HTTPS (443)`
   - Source: `192.168.100.0/24` (or any secondary test CIDR)
   - Description: `Manual emergency change - troubleshooting`
5. Save rules.

### Phase C: Detect the Drift (`terraform plan -refresh-only`)
```bash
terraform plan -refresh-only
```
*Expected Output:*
```text
Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the
last "terraform apply" which may have affected this plan:

  # aws_security_group.app_sg has changed
  ~ resource "aws_security_group" "app_sg" {
      ~ ingress = [
            # (1 unchanged element hidden)
          + {
              + cidr_blocks      = [
                  + "192.168.100.0/24",
                ]
              + description      = "Manual emergency change - troubleshooting"
              + from_port        = 443
              + protocol         = "tcp"
              + to_port          = 443
            },
        ]
    }

This is a refresh-only plan.
```

### Phase D: Remediation Option 1 – Revert AWS Back to Approved Code
If the manual change was unauthorized, force AWS to match your Git code:
```bash
terraform plan
terraform apply
```
*Result:* Terraform automatically removes the unauthorized `192.168.100.0/24` rule from AWS!

### Phase E: Remediation Option 2 – Accept the Manual Change into State
If the change was approved and you want to accept it into state:
```bash
terraform apply -refresh-only
```
*Note:* You must also update your `.tf` code to match, otherwise the next standard `terraform apply` will revert it!

---

## 6. Interview Questions & Expert Answers

**Q1: What is the difference between `terraform plan` and `terraform plan -refresh-only`?**  
*Answer:* `terraform plan` compares the `.tf` code against the real world and proposes changes to bring AWS in line with code. `terraform plan -refresh-only` only queries AWS to detect what changed outside Terraform, and proposes updating the **state file** to match the real world, without proposing any changes to AWS resources.

**Q2: What is the risk of running `terraform apply -refresh-only` blindly?**  
*Answer:* If an attacker or rogue engineer added malicious ingress rules (e.g. `0.0.0.0/0` on SSH/RDP), running `-refresh-only` accepts that malicious change into your state file instead of wiping it out. Always review drift diffs carefully.

---

## 7. Cost & Security Review
- **Cost:** Security Groups have **$0.00** hourly or monthly charges in AWS.
- **Security:** Never leave `0.0.0.0/0` open on management ports. Lab uses isolated test CIDRs.
