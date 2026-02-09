output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnets" {
  value = module.network.public_subnet_ids
}

output "app_private_subnets" {
  value = module.network.app_private_subnet_ids
}

output "db_private_subnets" {
  value = module.network.db_private_subnet_ids
}

output "nat_gateways" {
  value = module.network.nat_gateway_ids
}