resource "aws_db_subnet_group" "db_subnets" {
  name       = "main"
  subnet_ids = aws_subnet.private_db_subnets[*].id
  tags = merge(module.namespace.tags, {Name = "My DB subnet group"})
}