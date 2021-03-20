
#VPC
resource "aws_vpc" "And_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

#SUBNETS

#IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.And_vpc.id
  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

#NAT ELASTIC IP
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

#NAT GATEWAY
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  tags = {
    Name        = "${var.environment}-natgw"
    Environment = var.environment
  }
}

#PUBLIC SUBNET
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.And_vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.environment} -${element(var.availability_zones, count.index)}-public-subnet"
    Environment = var.environment
  }
}


#PRIVATE SUBNET
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.And_vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = var.environment
  }
}


#PUBLIC SUBNET ROUTE TABLE
resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.And_vpc.id
  tags = {
    Name        = "${var.environment}-publicRT"
    Environment = var.environment
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.publicRT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.publicRT.id
}

#PRIVATE SUBNET ROUTE TABLE
resource "aws_route_table" "privateRT" {
  vpc_id = aws_vpc.And_vpc.id
  tags = {
    Name        = "${var.environment} -privateRT"
    Environment = var.environment
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.privateRT.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.privateRT.id
}



#LOADBALANCER
resource "aws_security_group" "ElbSG" {
  name        = "ElbSG"
  description = "Allow HTTP/HTTPS traffic to instances through Elastic Load Balancer"
  vpc_id      = aws_vpc.And_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ELBSG"
    Environment = var.environment
  }
}

resource "aws_lb" "WebserverELB" {
  name               = "WebserverELB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ElbSG.id]
  subnets            = aws_subnet.public_subnet.*.id

}


resource "aws_lb_listener" "ListenerELB" {
  load_balancer_arn = aws_lb.WebserverELB.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.skyetag.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_groupELB.arn
  }

}

resource "aws_lb_listener" "https_redirect" {
  load_balancer_arn = aws_lb.WebserverELB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "target_groupELB" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.And_vpc.id

  health_check {
    healthy_threshold   = 2
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}




#SECURITY_GROUP
resource "aws_security_group" "WebserverSG" {
  name        = "${var.environment}-default-sg"
  description = "Allows SSH,HTTP, HTTPS "
  vpc_id      = aws_vpc.And_vpc.id
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-WebserverSG"
    Environment = var.environment
  }
}



#AUTOSCALING
#LAUNCH CONFIGURATION
resource "aws_launch_configuration" "WebserverLC" {
  name_prefix = "test-"
  image_id      = var.ec2_ami
  instance_type = var.ec2_instance_type
  key_name      = "Sysops"
  security_groups             = [aws_security_group.WebserverSG.id]
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

#AUTO-SCALING GROUP
resource "aws_autoscaling_group" "WebserverASG" {
  name                 = "${aws_launch_configuration.WebserverLC.name}-asg"
  min_size             = 2
  desired_capacity     = 2
  max_size             = 4
  health_check_type    = "ELB"
  load_balancers       = [aws_lb.WebserverELB.id]
  launch_configuration = aws_launch_configuration.WebserverLC.name
  vpc_zone_identifier  = aws_subnet.private_subnet.*.id
  target_group_arns    = [aws_lb_target_group.target_groupELB.arn]


  lifecycle {
    create_before_destroy = true
  }

}

#AUTOSCALING POLICY
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale_up_policy"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.cool_down
  autoscaling_group_name = aws_autoscaling_group.WebserverASG.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale_up_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.scale_up_period
  statistic           = "Average"
  threshold           = var.GreaterThanOrEqualToThreshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.WebserverASG.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.WebserverASG.name
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale_down_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.scale_down_period
  statistic           = "Average"
  threshold           = var.LessThanOrEqualToThreshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.WebserverASG.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_down_policy.arn]
}



#CERTIFICATE_MANAGER
resource "aws_acm_certificate" "skyetag" {
  domain_name               = "*.skyetag.com"
  subject_alternative_names = ["skyetag.com"]
  validation_method         = "DNS"
  tags = {
    Name        = "${var.environment} -certificate"
    Environment = var.environment
  }
}

resource "aws_route53_zone" "dev" {
  name = "www.skyetag.com"
  tags = {
    Name        = "${var.environment}-route53"
    Environment = var.environment
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.skyetag.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.dev.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [
    each.value.record,
  ]

  allow_overwrite = true
}




resource "aws_acm_certificate_validation" "skyetag" {
  certificate_arn         = aws_acm_certificate.skyetag.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}




