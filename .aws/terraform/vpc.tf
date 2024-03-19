resource "aws_vpc" "wordpress_vpc" {
  cidr_block       = "17.0.0.0/16"
  instance_tenancy = "default"

  tags = merge(module.namespace.tags, {Name = "Wordpress VPC"})
}