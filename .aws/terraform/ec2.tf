# Bastion host security group
resource "aws_security_group" "ec2_bastion_sg" {
  name        = "ec2_bastion_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.wordpress_vpc.id
  tags = merge(module.namespace.tags, {Name = "ec2-bastion-sg"})
}

resource "aws_vpc_security_group_ingress_rule" "ec2_bastion_sg_ssh" {
  security_group_id = aws_security_group.ec2_bastion_sg.id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  tags = merge(module.namespace.tags, {Name = "allow-ssh"})
}

resource "aws_vpc_security_group_ingress_rule" "ec2_bastion_sg_http" {
  security_group_id = aws_security_group.ec2_bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags = merge(module.namespace.tags, {Name = "allow-bastion-http"})
}

# resource "aws_vpc_security_group_ingress_rule" "allow_rds_bastion" {
#   security_group_id = aws_security_group.ec2_bastion_sg.id
#   referenced_security_group_id = aws_security_group.rds_sg.id
#   from_port         = 3306
#   ip_protocol       = "tcp"
#   to_port           = 3306
#   tags = merge(module.namespace.tags, {Name = "allow-rds-inbound-bastion"})
# }

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ec2_bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
  tags = merge(module.namespace.tags, {Name = "allow-outbound"})
}

# Wordpress ec2 security group
resource "aws_security_group" "ec2_wordpress_sg" {
  name        = "ec2_wordpress_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.wordpress_vpc.id
  tags = merge(module.namespace.tags, {Name = "ec2-wordpress-sg"})
}

resource "aws_vpc_security_group_ingress_rule" "ec2_wordpress_sg_ssh" {
  security_group_id = aws_security_group.ec2_wordpress_sg.id
  referenced_security_group_id = aws_security_group.ec2_bastion_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  tags = merge(module.namespace.tags, {Name = "allow-bastion-ssh"})
}

resource "aws_vpc_security_group_ingress_rule" "ec2_wordpress_sg_http" {
  security_group_id = aws_security_group.ec2_wordpress_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags = merge(module.namespace.tags, {Name = "allow-alb-http"})
}

resource "aws_vpc_security_group_ingress_rule" "ec2_wordpress_sg_https" {
  security_group_id = aws_security_group.ec2_wordpress_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  tags = merge(module.namespace.tags, {Name = "allow-alb-https"})
}

# resource "aws_vpc_security_group_ingress_rule" "allow_rds_wordpress" {
#   security_group_id = aws_security_group.ec2_wordpress_sg.id
#   referenced_security_group_id = aws_security_group.rds_sg.id
#   from_port         = 3306
#   ip_protocol       = "tcp"
#   to_port           = 3306
#   tags = merge(module.namespace.tags, {Name = "allow-rds-inbound-wordpress"})
# }

# EC2 Role
# needs s3 efs and rds