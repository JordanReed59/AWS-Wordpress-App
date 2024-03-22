resource "aws_db_subnet_group" "db_subnets" {
  name       = "db_subnet_group"
  subnet_ids = aws_subnet.private_db_subnets[*].id
  tags = merge(module.namespace.tags, {Name = "My DB subnet group"})
}

# RDS instance
resource "aws_db_instance" "wordpress_db" {
  allocated_storage    = 20
  db_name              = "WordpressDB"
  identifier           = "wordpress"
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  apply_immediately    = true
  availability_zone    = "us-east-1b"
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  tags = merge(module.namespace.tags, {Name = "WordpressDB"})
#   multi_az             = true
}

# Security group for ec2 access
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow MYSQL/Aurora inbound traffic"
  vpc_id      = aws_vpc.wordpress_vpc.id
  tags = merge(module.namespace.tags, {Name = "rds-sg"})
}

resource "aws_vpc_security_group_ingress_rule" "rds_sg_mysql_access" {
  security_group_id            = aws_security_group.rds_sg.id
  # referenced_security_group_id = aws_security_group.ec2_wordpress_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
  tags = merge(module.namespace.tags, {Name = "allow-mysql"})
}