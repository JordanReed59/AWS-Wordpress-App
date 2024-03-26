resource "aws_eip" "eip" {
  count      = 2
#   domain     = "vpc"
  tags       = module.namespace.tags
  depends_on = [aws_internet_gateway.internet_gw]
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(aws_eip.eip)
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  tags          = merge(module.namespace.tags, { Name = "Nat GW ${count.index + 1}" })
  depends_on    = [aws_internet_gateway.internet_gw]
}