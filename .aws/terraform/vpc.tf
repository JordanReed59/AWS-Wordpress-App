# VPC
resource "aws_vpc" "wordpress_vpc" {
  cidr_block       = "17.0.0.0/16"
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