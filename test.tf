module "webserver" {
  source                        = "github.com/KofoworolaOgunleye/Terraform"
  region                        = var.region
  profile                       = var.profile
  vpc_cidr                      = var.vpc_cidr
  environment                   = var.environment
  public_subnets_cidr           = var.public_subnets_cidr
  private_subnets_cidr          = var.private_subnets_cidr
  availability_zones            = var.availability_zones
  ec2_ami                       = var.ec2_ami
  ec2_instance_type             = var.ec2_instance_type
  cool_down                     = var.cool_down
  scale_up_period               = var.scale_up_period
  GreaterThanOrEqualToThreshold = var.GreaterThanOrEqualToThreshold
  scale_down_period             = var.scale_down_period
  LessThanOrEqualToThreshold    = var.LessThanOrEqualToThreshold
}
output "elb_dns_name" {
  value       = module.webserver.elb_dns_name
  description = "load balancer dns"
}

output "acm_certificate_arn" {
  value       = module.webserver.acm_certificate_arn
  description = "arn"
}