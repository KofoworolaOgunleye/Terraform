
region  = "eu-west-2"
profile = "MyAWS"

vpc_cidr = "10.0.0.0/16"

environment = "Test"

public_subnets_cidr = ["10.0.32.0/20", "10.0.96.0/20", "10.0.160.0/20"]

availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

private_subnets_cidr = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

ec2_ami = "ami-0df2b1f358a21cb5d"

ec2_instance_type = "t2.micro"

cool_down = 300

scale_up_period = "120"

GreaterThanOrEqualToThreshold = "60"

scale_down_period = "120"

LessThanOrEqualToThreshold = "10"
