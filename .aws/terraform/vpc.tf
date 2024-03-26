# VPC
resource "aws_vpc" "wordpress_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = merge(module.namespace.tags, {Name = "Wordpress VPC"})
}
# Internet Gateway
resource "aws_internet_gateway" "internet_gw" {
 vpc_id = aws_vpc.wordpress_vpc.id
 tags = merge(module.namespace.tags, {Name = "Wordpress VPC IGW"})
}

# Subnets
resource "aws_subnet" "public_subnets" {
 count             = length(var.public_sn_cidrs)
 vpc_id            = aws_vpc.wordpress_vpc.id
 cidr_block        = element(var.public_sn_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 tags = merge(module.namespace.tags, {Name = "Public Subnet ${count.index + 1}"})
}
 
resource "aws_subnet" "private_compute_subnets" {
 count             = length(var.private_compute_sn_cidrs)
 vpc_id            = aws_vpc.wordpress_vpc.id
 cidr_block        = element(var.private_compute_sn_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 tags = merge(module.namespace.tags, {Name = "Private Compute Subnet ${count.index + 1}"})
}

resource "aws_subnet" "private_db_subnets" {
 count             = length(var.private_db_sn_cidrs)
 vpc_id            = aws_vpc.wordpress_vpc.id
 cidr_block        = element(var.private_db_sn_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 tags = merge(module.namespace.tags, {Name = "Private DatabaseSubnet ${count.index + 1}"})
}

# Route Tables
# public route table
resource "aws_route_table" "publc_rt" {
 vpc_id = aws_vpc.wordpress_vpc.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.internet_gw.id
 }
 tags = merge(module.namespace.tags, {Name = "Public Route Table"})
}

resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_sn_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.publc_rt.id
}

# private compute route table
# resource "aws_route_table" "private_compute_rt" {
#  vpc_id = aws_vpc.wordpress_vpc.id
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.internet_gw.id
#  }
#  tags = merge(module.namespace.tags, {Name = "Private Compute Route Table"})
# }

# private compute route table
resource "aws_route_table" "private_compute_rt" {
 count = length(var.public_sn_cidrs)
 vpc_id = aws_vpc.wordpress_vpc.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_nat_gateway.nat_gw[count.index].id
 }
 tags = merge(module.namespace.tags, {Name = "Private Compute Route Table ${count.index}"})
}

resource "aws_route_table_association" "private_compute_subnet_asso" {
 count = length(var.public_sn_cidrs)
 subnet_id      = aws_subnet.private_compute_subnets[count.index].id
 route_table_id = aws_route_table.private_compute_rt[count.index].id
}

# private database route table
resource "aws_route_table" "private_db_rt" {
 vpc_id = aws_vpc.wordpress_vpc.id
 tags = merge(module.namespace.tags, {Name = "Private Database Route Table"})
}

resource "aws_route_table_association" "private_db_subnet_asso" {
 count = length(var.public_sn_cidrs)
 subnet_id      = element(aws_subnet.private_db_subnets[*].id, count.index)
 route_table_id = aws_route_table.private_db_rt.id
}

# VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.wordpress_vpc.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = aws_route_table.private_compute_rt[*].id
  tags = merge(module.namespace.tags, {Name = "my-s3-endpoint"})
}