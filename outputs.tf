output "elb_dns_name" {
  value       = aws_lb.WebserverELB.dns_name
  description = "load balancer dns"
}

output "acm_certificate_arn" {
  value       = aws_acm_certificate.skyetag.arn
  description = "arn of acm certificate"
} 