variable "vpc_cidr" {
  description = "cidr value for the main vpc"
  type = string
}

variable "public_subnet_cidr" {
  description = "public subnet cidr"
  type = list(string)
}

variable "app_private_subnet_cidr" {
  description = "app private subnet cidr"
  type = list(string)
}

variable "db_private_subnet_cidr" {
  description = "db private subnet cidr"
    type = list(string)
}


# ----------------------------------------------------
#  local clean up variables
#----------------------------------------------------

locals {
  public_subnets = [
    for i in range(length(var.public_subnet_cidr)) : {
      cidr = var.public_subnet_cidr[i]
      az   = data.aws_availability_zones.available.names[i]
    }
  ]
  app_private_subnets = [
    for i in range(length(var.app_private_subnet_cidr)) : {
      cidr = var.app_private_subnet_cidr[i]
      az   = data.aws_availability_zones.available.names[i]
    }
  ]
  db_private_subnets = [
    for i in range(length(var.db_private_subnet_cidr)) : {
      cidr = var.db_private_subnet_cidr[i]
      az   = data.aws_availability_zones.available.names[i]
    }
  ]
}




# after defining the local variables, you can use them in your module like this:

#before:
# count             = length(var.public_subnet_cidr)
# cidr_block        = var.public_subnet_cidr[count.index]
# availability_zone = var.availability_zone[count.index]


#after:
# count             = length(local.public_subnets)
# cidr_block        = local.public_subnets[count.index].cidr
# availability_zone = local.public_subnets[count.index].az

