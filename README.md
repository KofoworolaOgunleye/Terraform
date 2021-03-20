# A Load balanced web front in AWS
Launched AWS resources in a VPC that consists of public and private subnets with the Load Balancer placed in the public subnet and Ec2 instances placed in the private subnet.
This infrastructure has a minimum of 2 instances and a maximum of 4 that scales across 3 availability zones based on policies defined and uses AWS Certificate Manager for SSL certificate and domain name validation through Route53.
