aws_region = "ap-south-2"

vpc_cidr = "10.10.0.0/16"

public_subnet_cidr_list = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

app_private_subnet_cidr_list = [
  "10.10.3.0/24",
  "10.10.4.0/24"
]

db_private_subnet_cidr_list = [
  "10.10.5.0/24",
  "10.10.6.0/24"
]

availability_zone_list = [
  "ap-south-2a",
  "ap-south-2b"
]

alb_name           = "three-tier-web-alb-public"
internal_alb_name  = "three-tier-web-alb-internal"

instance_type     = "t2.micro"
db_instance_class = "db.t3.micro"
