variable "vpc_id" {
  description = "vpc id"
}

variable "app_port" {
  description = "port to open for app in sg"
  type = number
  default = 8080
}

variable "db_port" {
  description = "port to open of db in sg"
  type = number
  default = 5432
}