variable "repo" {
  type = string
}

variable "branch" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "public_sn_cidrs" {
  type = list(string)
  description = "Public Subnet CIDR blocks"
  default = [ "17.0.1.0/24", "17.0.2.0/24" ]
}

variable "private_compute_sn_cidrs" {
  type = list(string)
  description = "Private compute subnet CIDR blocks"
  default = [ "17.0.3.0/24", "17.0.4.0/24" ]
}

variable "private_db_sn_cidrs" {
  type = list(string)
  description = "Private database subnet CIDR blocks"
  default = [ "17.0.5.0/24", "17.0.6.0/24" ]
}

variable "azs" {
  type = list(string)
  description = "Availability Zones"
  default = [ "us-east-1b", "us-east-1c" ]
}