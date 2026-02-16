# AWS 3-Tier Architecture using Terraform

This project provisions a **production-style 3-tier architecture on AWS** using **Terraform**. It is designed for learning, validation, and interview preparation, while staying **AWS Free Tier–friendly**.

---

## 🏗 Architecture Overview

**Traffic Flow:**
```
User
 → Public Application Load Balancer (Internet-facing)
 → Web Tier (EC2 Auto Scaling Group – Public Subnets)
 → Internal Application Load Balancer (Private)
 → App Tier (EC2 Auto Scaling Group – Private Subnets)
 → PostgreSQL RDS (Private Subnets)
```

Each tier is isolated using **separate subnets and security groups**, following **least-privilege networking**.

---

## 🧱 Components Created

### 1. Network Layer
- VPC
- Public subnets (multi-AZ)
- Private subnets for App tier
- Private subnets for DB tier
- Internet Gateway
- NAT Gateways (one per AZ)
- Route tables & associations

### 2. Security Groups
- **ALB SG** – Allows HTTP/HTTPS from the internet
- **Web EC2 SG** – Allows traffic only from ALB
- **Internal ALB SG** - Allows traffic only from Web tier (port 8080)
- **App EC2 SG** – Allows traffic only from Internal ALB
- **DB SG** – Allows PostgreSQL access only from App tier (port 5432)

### 3. Load Balancers
- Public Application Load Balancer

- Internet-facing
- Listener on port 80
- Target group for Web tier
- Health checks enabled

- Internal Application Load Balancer

- Internal (private subnets only)
- Listener on port 8080
- Target group for App tier
- Not publicly accessible

### 4. Web Tier
- EC2 Auto Scaling Group
- Launch Template
- Nginx installed via user-data
- Simple HTML page for validation
- No SSH keys (immutable infrastructure style)

### 5. App Tier
- EC2 Auto Scaling Group (private subnets)
- Launch Template
- Lightweight Python HTTP server
- Listens on port 8080

### 6. Database Tier
- Amazon RDS PostgreSQL
- Free-tier compatible instance
- Private subnets only
- Not publicly accessible
- Minimal allocated storage

---

## 📁 Project Structure

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── project_modules/
│   ├── network/
│   ├── security-groups/
│   ├── alb/
│   ├── internal-alb/
│   ├── web-asg/
│   ├── app-asg/
│   └── database/
└── README.md
```

---

## 🚀 How to Deploy

```bash
terraform init
terraform plan
terraform apply
```

After apply completes, wait **2–3 minutes** for Auto Scaling Groups and health checks to stabilize.

---


## 🔐 Security Notes

- Only the ALB is publicly accessible
- Web and App tiers are isolated using SG-to-SG rules
- Database is fully private
- SSH access is disabled by default
- Temporary debugging rules can be added but should be removed

---

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

---

## Summary

> “I built a multi-AZ 3-tier architecture using Terraform with ALB, auto-scaling web and app tiers, and a private PostgreSQL database. I validated internal connectivity, health checks, scaling behavior, and enforced least-privilege security using SG-to-SG rules.”

---

## 📌 Notes
- AMI was temporarily hardcoded for debugging
- PostgreSQL engine version was selected based on AWS regional availability

---


