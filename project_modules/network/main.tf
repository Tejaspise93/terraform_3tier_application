
# --------------------------------------------------------
# main tf file for network module
# --------------------------------------------------------

# --------------------------------------------------------
# main vpc
# --------------------------------------------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "three_tier_vpc"
  }
}


# --------------------------------------------------------
# internet gateway 
# --------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main_igw"
  }
}

# --------------------------------------------------------
# public subnet
# --------------------------------------------------------
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = local.public_subnets[count.index].cidr
  availability_zone       = local.public_subnets[count.index].az
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_${count.index + 1}"
  }
}

# --------------------------------------------------------
# app private subnet
# --------------------------------------------------------
resource "aws_subnet" "app_private_subnet" {
  count             = length(local.app_private_subnets)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = local.app_private_subnets[count.index].cidr
  availability_zone = local.app_private_subnets[count.index].az
  tags = {
    Name = "app_private_subnet_${count.index + 1}"
  }

}


# --------------------------------------------------------
# db private subnet
# --------------------------------------------------------
resource "aws_subnet" "db_private_subnet" {
  count             = length(local.db_private_subnets)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = local.db_private_subnets[count.index].cidr
  availability_zone = local.db_private_subnets[count.index].az
  tags = {
    Name = "db_private_subnet_${count.index + 1}"
  }
}


# --------------------------------------------------------
# route table for public subnet
# --------------------------------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}


# --------------------------------------------------------
# route table association for public subnet
# --------------------------------------------------------
resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# --------------------------------------------------------
# elastic ip for nat gateway
# --------------------------------------------------------
resource "aws_eip" "nat" {
  count  = length(local.public_subnets)
  tags = {
    Name = "nat-eip-${count.index + 1}"
  }
}



# --------------------------------------------------------
# nat gateway for private subnets
# --------------------------------------------------------
resource "aws_nat_gateway" "nat_gw" {
  count         = length(aws_subnet.public_subnet)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  tags = {
    Name = "nat_gw_${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]

}

# --------------------------------------------------------
# private route table for app and association
# --------------------------------------------------------
resource "aws_route_table" "app_private_rt" {
  count  = length(aws_nat_gateway.nat_gw)
  vpc_id = aws_vpc.main_vpc.id

  #Subnet index 0 → AZ-A → NAT-A
  #Subnet index 1 → AZ-B → NAT-B
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "app-private-rt-${count.index + 1}"
  }
}


resource "aws_route_table_association" "app_private" {
  count          = length(aws_subnet.app_private_subnet)
  subnet_id      = aws_subnet.app_private_subnet[count.index].id
  route_table_id = aws_route_table.app_private_rt[count.index].id
}


# --------------------------------------------------------
# private route table for db and association
# --------------------------------------------------------
resource "aws_route_table" "db_private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "db-private-rt"
  }
}

resource "aws_route_table_association" "db_private" {
  count          = length(aws_subnet.db_private_subnet)
  subnet_id      = aws_subnet.db_private_subnet[count.index].id
  route_table_id = aws_route_table.db_private_rt.id
}
