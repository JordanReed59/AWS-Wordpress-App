resource "aws_db_subnet_group" "db_subnets" {
  name       = "db_subnet_group"
  subnet_ids = aws_subnet.private_db_subnets[*].id
  tags = merge(module.namespace.tags, {Name = "My DB subnet group"})
}

# RDS instance
resource "aws_db_instance" "wordpress_db" {
  allocated_storage    = 20
  db_name              = "WordpressDB"
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  apply_immediately    = true
  availability_zone    = "us-east-1b"
#   multi_az             = true
}