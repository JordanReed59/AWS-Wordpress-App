# Security Group
resource "aws_security_group" "efs_sg" {
  name        = "efs_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.wordpress_vpc.id
  tags = merge(module.namespace.tags, {Name = "efs-sg"})
}

resource "aws_vpc_security_group_ingress_rule" "efs_sg_ec2" {
  security_group_id = aws_security_group.efs_sg.id
  # referenced_security_group_id = aws_security_group.ec2_wordpress_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  from_port         = 2049
  ip_protocol       = "tcp"
  to_port           = 2049
  tags = merge(module.namespace.tags, {Name = "allow-ec2-sg-access"})
}

# EFS File Share
resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "wordpress-efs"
  tags = merge(module.namespace.tags, {Name = "WordpressEFS"})
}

resource "aws_efs_mount_target" "alpha" {
  file_system_id = aws_efs_file_system.wordpress_efs.id
  subnet_id      = aws_subnet.private_compute_subnets[0].id
  security_groups = [ aws_security_group.efs_sg.id ]
}

resource "aws_efs_mount_target" "beta" {
  file_system_id = aws_efs_file_system.wordpress_efs.id
  subnet_id      = aws_subnet.private_compute_subnets[1].id
  security_groups = [ aws_security_group.efs_sg.id ]
}