variable "aws_region" {
  description = "region needed to be used"
  default     = "ap-south-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_list" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_private_subnet_cidr_list" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "db_private_subnet_cidr_list" {
  type    = list(string)
  default = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zone_list" {
  type    = list(string)
  default = ["ap-south-2a", "ap-south-2b"]
}

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
  default     = "three-web-alb-internet-facing"
}

variable "internal_alb_name" {
  description = "name of internal alb"
  type        = string
  default     = "three-web-alb-internal"
}

variable "instance_type" {
  description = "instance type for the ec2 instances"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

#------------------- Sensitive Variables ------------------
# In a production environment, you should not hardcode sensitive information like database passwords in your Terraform code.
# Instead, use a secrets manager to securely manage sensitive data.
# For demonstration purposes, we are defining a default value here, but in a real-world scenario, 
# you should remove the default value and provide it securely during deployment.
#-------------------- Sensitive Variables ------------------
variable "db_password" {
  description = "Postgres DB password"
  type        = string
  sensitive   = true
  default     = "Password123"
}
