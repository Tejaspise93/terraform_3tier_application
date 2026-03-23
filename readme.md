# AWS 3-Tier Architecture using Terraform

This project provisions a production-style 3-tier architecture on AWS using Terraform. Infrastructure is managed via a Jenkins CI/CD pipeline with options to apply or destroy.

> **Note:** This project is configured for AWS Free Tier. Settings like `multi_az`, `deletion_protection`, and instance types are set conservatively. See the Notes section for production recommendations.

---

## Architecture Overview

Traffic flows through the following tiers:

```
User
 -> Public Application Load Balancer (Internet-facing)
 -> Web Tier (EC2 Auto Scaling Group – Public Subnets)
 -> Internal Application Load Balancer (Private)
 -> App Tier (EC2 Auto Scaling Group – Private Subnets)
 -> PostgreSQL RDS (Private Subnets)
```

Each tier is isolated using separate subnets and security groups, following least-privilege networking.

---

## Components

### Network
- VPC with DNS support enabled
- Public subnets (multi-AZ) with auto-assign public IP
- Private subnets for App and DB tiers (multi-AZ)
- Internet Gateway
- NAT Gateways — one per AZ
- Route tables and associations per tier

### Security Groups
- **ALB SG** — Allows HTTP (80) and HTTPS (443) from the internet
- **Web EC2 SG** — Allows inbound port 80 from ALB SG only
- **Internal ALB SG** — Allows inbound port 8080 from Web EC2 SG only
- **App EC2 SG** — Allows inbound port 8080 from Internal ALB SG only; outbound to DB on port 5432
- **DB SG** — Allows PostgreSQL (5432) from App EC2 SG only

### Load Balancers
- **Public ALB** — Internet-facing, listener on port 80
- **Internal ALB** — Private subnets, listener on port 8080

### Web Tier
- EC2 Auto Scaling Group in public subnets
- Latest Amazon Linux 2023 AMI (fetched dynamically)
- Nginx serving a simple HTML page
- CPU-based scaling policy (threshold: 50%)
- SSH disabled by default

### App Tier
- EC2 Auto Scaling Group in private subnets
- Latest Amazon Linux 2023 AMI (fetched dynamically)
- Python HTTP server on port 8080, managed via systemd
- Auto-restart on crash and reboot
- CPU-based scaling policy (threshold: 50%)

### Database
- Amazon RDS PostgreSQL in private subnets
- Engine version fetched dynamically per region
- Not publicly accessible
- `db.t3.micro` instance class

---

## Project Structure

```
PROJECT/
├── Jenkinsfile
├── main.tf
├── output.tf
├── provider.tf
├── variable.tf
├── terraform.tfvars
├── README.md
└── project_modules/
    ├── alb/
    ├── app_asg/
    │   └── scripts/app_user_data.sh
    ├── database/
    ├── internal_alb/
    ├── network/
    ├── security_groups/
    └── web_asg/
        └── scripts/web_user_data.sh
```

---

## Deployment

### Prerequisites
- Terraform >= 1.0 installed on the Jenkins server
- Jenkins server with AWS credentials configured
- AWS CLI configured with appropriate credentials

### Option 1 — Jenkins Pipeline (Recommended)

1. Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as secret text credentials in Jenkins
2. Create a new Pipeline job and set the definition to **Pipeline script from SCM**
3. Set SCM to **Git** and provide your repository URL
4. Set Script Path to `Jenkinsfile`
5. Save and run **Build Now** once to let Jenkins load the pipeline
6. From the second run, use **Build with Parameters**
   - Select `apply` to provision infrastructure
   - Select `destroy` to tear it down

### Option 2 — Terraform CLI

```bash
terraform init
terraform plan
terraform apply
```

### Cleanup

```bash
terraform destroy
```

---

## Validating the Deployment

**Web Tier** — Open the public ALB DNS name in a browser:
```
http://<alb-dns-name>.<region>.elb.amazonaws.com
```
Expected response: `Web Tier is UP`

**Target Groups** — AWS Console > EC2 > Target Groups:
- `web-target-group` — 2 Healthy
- `app-target-group` — 2 Healthy

**Auto Scaling Groups** — AWS Console > EC2 > Auto Scaling Groups:
- `web-asg` — desired 2, running 2
- `app-asg` — desired 2, running 2

**RDS** — AWS Console > RDS > Databases > `postgres-db`:
- Status: Available
- Publicly Accessible: No

---

## Security Design

- Only the public ALB is internet-facing
- All inter-tier communication uses security group-to-security group rules, no CIDR-based rules between tiers
- Database has no public access
- SSH is disabled on all instances by default
- AWS credentials are stored in the Jenkins credential store and never hardcoded

---

## Region Support

All region-specific values are fetched dynamically:

- **AMI** — `data "aws_ami"` fetches the latest Amazon Linux 2023
- **Availability Zones** — `data "aws_availability_zones"` fetches available AZs
- **RDS engine version** — `data "aws_rds_engine_version"` fetches a supported version

To deploy in a different region, change only `aws_region` in `terraform.tfvars`.

---

## Notes

| Setting | Current Value | Production Recommendation |
|---------|--------------|--------------------------|
| `instance_type` | `t3.micro` | Size based on workload |
| `db_instance_class` | `db.t3.micro` | Size based on workload |
| `multi_az` | `false` | `true` |
| `deletion_protection` | `false` | `true` |
| `skip_final_snapshot` | `true` | `false` |
| DB password | `terraform.tfvars` | AWS Secrets Manager |
| SSH access | Disabled | Enable with bastion host if needed |
| Terraform state | Local | S3 remote backend |