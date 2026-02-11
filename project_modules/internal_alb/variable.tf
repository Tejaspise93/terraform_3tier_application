variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "internal_alb_sg_id" {
  type = string
}
variable "internal_alb_name" {
  type = string
}

variable "load_balancer_type" {
  description = "Type of the load balancer (application or network)"
  type        = string
  default     = "application"
}