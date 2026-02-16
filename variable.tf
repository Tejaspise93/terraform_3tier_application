variable "aws_region" {
  description = "region needed to be used"
}

variable "vpc_cidr" {
  type    = string
}

variable "public_subnet_cidr_list" {
  type    = list(string)
}

variable "app_private_subnet_cidr_list" {
  type    = list(string)
}

variable "db_private_subnet_cidr_list" {
  type    = list(string)
}

variable "availability_zone_list" {
  type    = list(string)
}

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
}

variable "internal_alb_name" {
  description = "name of internal alb"
  type        = string
}

variable "instance_type" {
  description = "instance type for the ec2 instances"
  type        = string
}

variable "db_instance_class" {
  type    = string
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
