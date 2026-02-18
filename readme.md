# AWS 3-Tier Architecture using Terraform

This project provisions a **production-style 3-tier architecture on AWS** using **Terraform**.

> ⚠️ **Note:** This project is currently configured for AWS Free Tier. Some settings like `multi_az`, `deletion_protection`, and instance types are set conservatively. See the Notes section for production recommendations.

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

## 🧱 Components

### Network
- VPC with DNS hostnames and DNS support enabled
- Public subnets (multi-AZ) with auto-assign public IP
- Private subnets for App tier (multi-AZ)
- Private subnets for DB tier (multi-AZ)
- Internet Gateway
- NAT Gateways — one per AZ for high availability
- Route tables and associations per tier

### Security Groups
- **ALB SG** — Allows HTTP (80) and HTTPS (443) from internet
- **Web EC2 SG** — Allows inbound port 80 from ALB SG only
- **Internal ALB SG** — Allows inbound port 8080 from Web EC2 SG only
- **App EC2 SG** — Allows inbound port 8080 from Internal ALB SG only, outbound to DB on port 5432
- **DB SG** — Allows PostgreSQL (5432) from App EC2 SG only

### Load Balancers
- **Public ALB** — Internet-facing, listener on port 80, health check matcher `200`
- **Internal ALB** — Private subnets only, listener on port 8080, health check on port 8080 with matcher `200`

### Web Tier
- EC2 Auto Scaling Group in public subnets
- Latest Amazon Linux 2023 AMI fetched dynamically
- Nginx serving a simple HTML page
- CPU-based target tracking scaling policy (threshold: 50%)
- SSH disabled by default

### App Tier
- EC2 Auto Scaling Group in private subnets
- Latest Amazon Linux 2023 AMI fetched dynamically
- Python HTTP server on port 8080 managed via systemd service
- Auto-restart on crash and on reboot via systemd
- CPU-based target tracking scaling policy (threshold: 50%)

### Database
- Amazon RDS PostgreSQL in private subnets
- Engine version fetched dynamically per region
- Not publicly accessible
- `db.t3.micro` instance class

---

## 📁 Project Structure

```
PROJECT/
├── .gitattributes
├── .gitignore
├── main.tf
├── output.tf
├── provider.tf
├── variable.tf
├── terraform.tfvars
├── README.md
└── project_modules/
    ├── alb/
    │   ├── main.tf
    │   ├── output.tf
    │   └── varaibles.tf
    ├── app_asg/
    │   ├── scripts/
    │   │   └── app_user_data.sh
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    ├── database/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    ├── internal_alb/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variable.tf
    ├── network/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    ├── security_groups/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    └── web_asg/
        ├── scripts/
        │   └── web_user_data.sh
        ├── main.tf
        ├── output.tf
        └── variables.tf
```

---

## 🚀 Deployment

### Prerequisites
- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- An AWS account

### Steps

```bash
terraform init
terraform plan
terraform apply
```

After apply completes, wait **5 minutes** for instances to boot and health checks to stabilize.

To force instances to pick up launch template changes after an update:
```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name web-asg --region <your-region>
aws autoscaling start-instance-refresh --auto-scaling-group-name app-asg --region <your-region>
```

### Cleanup

```bash
terraform destroy
```

---

## ✅ Validating the Deployment

**Web Tier**
Open the public ALB DNS name in a browser:
```
http://<alb-dns-name>.<region>.elb.amazonaws.com
```
Expected response: `Web Tier is UP`

**Target Groups**
AWS Console → EC2 → Target Groups:
- `web-target-group` → 2 Healthy
- `app-target-group` → 2 Healthy

**Auto Scaling Groups**
AWS Console → EC2 → Auto Scaling Groups:
- `web-asg` → desired 2, running 2
- `app-asg` → desired 2, running 2

**RDS**
AWS Console → RDS → Databases → `postgres-db`:
- Status: Available
- Publicly Accessible: No

---

## 🔐 Security Design

- Only the public ALB is internet-facing
- All inter-tier communication uses SG-to-SG rules — no CIDR-based rules between tiers
- Database has no public access
- SSH is disabled on all instances by default

---

## 🌍 Region Agnostic

All region-specific values are fetched dynamically:

- **AMI** — `data "aws_ami"` fetches latest Amazon Linux 2023
- **Availability Zones** — `data "aws_availability_zones"` fetches available AZs
- **RDS engine version** — `data "aws_rds_engine_version"` fetches a supported version

To deploy in a different region, change only `aws_region` in `terraform.tfvars`.

---

## 📌 Notes

| Setting | Current Value | Production Recommendation |
|---------|--------------|--------------------------|
| `instance_type` | `t3.micro` | Size based on workload |
| `db_instance_class` | `db.t3.micro` | Size based on workload |
| `multi_az` | `false` | `true` |
| `deletion_protection` | `false` | `true` |
| `skip_final_snapshot` | `true` | `false` |
| DB password | `terraform.tfvars` | AWS Secrets Manager |
| SSH access | Disabled | Enable with bastion host if needed |