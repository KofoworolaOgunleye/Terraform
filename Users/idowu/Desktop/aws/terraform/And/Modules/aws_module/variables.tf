variable "region" {
  description = "MyAWS"
  type        = string
}

variable "profile" {
  description = "MyAWS"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "VPC"
  type        = string
}

variable "public_subnets_cidr" {
  description = "List of public subnets for the VPC"
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "List of private subnets for the VPC"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones names in the region"
  type        = list(string)
}

variable "ec2_ami" {
  type        = string
  description = "EC2 AMI"
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "cool_down" {
  type        = number
  description = "Time required to temporarily suspend any scaling activities in order to allow the newly launched EC2 instance(s) some time to start handling the application traffic."
}
variable "scale_up_period" {
  type        = string
  description = "The period in seconds over which the specified statistic is applied."
}


variable "GreaterThanOrEqualToThreshold" {
  type        = string
  description = "The value against which the specified statistic is compared"
}

variable "scale_down_period" {
  type        = string
  description = "The period in seconds over which the specified statistic is applied"
}

variable "LessThanOrEqualToThreshold" {
  type        = string
  description = "The value against which the specified statistic is compared"
}