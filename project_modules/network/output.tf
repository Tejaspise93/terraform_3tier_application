output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "app_private_subnet_ids" {
  value = aws_subnet.app_private_subnet[*].id
}

output "db_private_subnet_ids" {
  value = aws_subnet.db_private_subnet[*].id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.nat_gw[*].id
}