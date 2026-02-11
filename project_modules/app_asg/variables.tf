variable "private_subnet_ids" {
  type = list(string)
}

variable "app_sg_id" {
  type = string
}

variable "instance_type" {
  type    = string
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "key_name" {
  type    = string
  default = null
}

variable "app_target_group_arn" {
  type = string
}
