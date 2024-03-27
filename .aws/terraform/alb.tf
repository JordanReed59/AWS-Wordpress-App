# Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.wordpress_vpc.id
  tags = merge(module.namespace.tags, {Name = "alb-sg"})
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_ipv4_https" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  tags = merge(module.namespace.tags, {Name = "allow-https"})
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_ipv4_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags = merge(module.namespace.tags, {Name = "allow-http"})
}

# Target Group
resource "aws_lb_target_group" "wordpress_tg" {
  name     = "wordpress-tg"
  port     = 80  # Port 80 where WordPress is running
  protocol = "HTTP"
  vpc_id   = aws_vpc.wordpress_vpc.id

  health_check {
    enabled             = true
    port                = 80  # Use port 80 for health checks
    interval            = 30
    protocol            = "HTTP"
    path                = "/"  # Use the root path for health checks
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = module.namespace.tags
}

resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.my_wp_asg.id
  lb_target_group_arn    = aws_lb_target_group.wordpress_tg.arn
}

# ALB
resource "aws_lb" "wordpress_alb" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = aws_subnet.public_subnets[*].id
}

resource "aws_lb_listener" "wordpress_listener" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
}

# Only if I get a domain and request a certificat
# if i do need to change the above listener to redirect to https
# resource "aws_lb_listener" "wordpress_listener" {
#   load_balancer_arn = aws_lb.wordpress_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.wordpress_tg.arn
#   }
# }