################### Security Groups ###################
# ###!!! update route table for private compute instances to route all internet traffic to nat gateways
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

resource "aws_vpc_security_group_ingress_rule" "ec2_wordpress_sg_http_bastion" {
  security_group_id = aws_security_group.ec2_wordpress_sg.id
  referenced_security_group_id = aws_security_group.ec2_bastion_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags = merge(module.namespace.tags, {Name = "allow-bastion-http"})
}

resource "aws_vpc_security_group_ingress_rule" "ec2_wordpress_sg_https" {
  security_group_id = aws_security_group.ec2_wordpress_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  tags = merge(module.namespace.tags, {Name = "allow-alb-https"})
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_traffic" {
  security_group_id = aws_security_group.ec2_wordpress_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
  tags = merge(module.namespace.tags, {Name = "allow-outbound"})
}

# EC2 Instance Profile and Role
resource "aws_iam_instance_profile" "test_profile" {
  name = "EC2-Wordpress-Profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "EC2-Wordpress-Role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = module.namespace.tags
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid = "AllowEFS"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite",
                "elasticfilesystem:DescribeMountTargets"
                
              ]
    resources = [aws_efs_file_system.wordpress_efs.arn]
  }
  statement {
    sid = "AllowS3"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.media_bucket.arn, "${aws_s3_bucket.media_bucket.arn}/*"]
  }
  statement {
    sid = "AllowEC2Describe"
    effect    = "Allow"
    actions   = [
      "ec2:DescribeInstances",
      "ec2:DescribeAvailabilityZones"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "Wordpress-S3-EFS-Policy"
  description = "Policy allowing access to S3 and EFS"
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.policy.arn
}

# Launch Template
data "aws_ami" "amzlinux2_wp" {
  owners      = ["self"]
  most_recent = true
  filter {
    name = "image-id"
    values = ["ami-03131ddd419193539"]
  }
}

resource "aws_launch_template" "wp_launch_template" {
  name = "Wordpress-Launch-Template"
  description = "My Wordpress Launch Template"
  image_id = data.aws_ami.amzlinux2_wp.id
  instance_type = "t2.micro"
  key_name = "WordpressKeyPair"
  update_default_version = true
  user_data = filebase64("${path.module}/files/bootstrap.sh")
  iam_instance_profile {
    arn = aws_iam_instance_profile.test_profile.arn
  }
  network_interfaces {
    security_groups = [aws_security_group.ec2_wordpress_sg.id]
  }
  monitoring {
    enabled = true
  }
  tag_specifications {
    resource_type = "instance"
    tags = merge(module.namespace.tags, {Name = "Wordpress"})
  }
}

# Autoscaling Group
resource "aws_autoscaling_group" "my_wp_asg" {
  name_prefix = "wordpressasg-"
  desired_capacity   = 2
  max_size           = 2
  min_size           = 2
  vpc_zone_identifier  = aws_subnet.private_compute_subnets[*].id
  health_check_type = "EC2"
  health_check_grace_period = 300 # default is 300 seconds  
  target_group_arns = [aws_lb_target_group.wordpress_tg.arn]
  # Launch Template
  launch_template {
    id      = aws_launch_template.wp_launch_template.id
    version = aws_launch_template.wp_launch_template.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = [ "desired_capacity" ] # You can add any argument from ASG here, if those has changes, ASG Instance Refresh will trigger
  }       
}
################### EC2 Role ###################

################### Bastion Host ###################
# Security Group
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

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ec2_bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
  tags = merge(module.namespace.tags, {Name = "allow-outbound"})
}

# Launch Template
data "aws_ami" "amzlinux2" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name = "image-id"
    values = ["ami-033a1ebf088e56e81"]
  }
}

resource "aws_launch_template" "bastion_launch_template" {
  name = "Bastion-Launch-Template"
  description = "My Bastion Host Launch Template"
  image_id = data.aws_ami.amzlinux2.id
  instance_type = "t2.micro"
  key_name = "MgmtKeyPair"
  update_default_version = true
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.ec2_bastion_sg.id]
  }
  monitoring {
    enabled = true
  }
  tag_specifications {
    resource_type = "instance"
    tags = merge(module.namespace.tags, {Name = "Bastion Host"})
  }
}

# Autoscaling Group
resource "aws_autoscaling_group" "my_asg" {
  name_prefix = "bastionasg-"
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  vpc_zone_identifier  = aws_subnet.public_subnets[*].id
  health_check_type = "EC2"
  health_check_grace_period = 300 # default is 300 seconds  
  # Launch Template
  launch_template {
    id      = aws_launch_template.bastion_launch_template.id
    version = aws_launch_template.bastion_launch_template.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = [ "desired_capacity" ] # You can add any argument from ASG here, if those has changes, ASG Instance Refresh will trigger
  }       
}
