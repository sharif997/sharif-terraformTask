#security Group for AWS ec2 instances to attach it to the Launch config 
resource "aws_security_group" "custom-ec2-sg" {
    name = "custom-ec2-sg"
    vpc_id = aws_vpc.sharif.id
    description = "Security group for Instances"
    
    #outgoing traffic
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
    #ingoing traffic
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      security_groups = [aws_security_group.custom-elb-sg.id]
    }
    tag {
      name = "Custom web Server security Group "
    }
}


#Define AutoScalingGroup Launch Config 
resource "aws_launch_configuration" "RHEL-LC" {
  name          = "web_config"
  image_id      = "ami-06640050dc3f556bb"                       #Amazon image id for RHEL -v8    
  instance_type = "t2.micro"
  key_name = "P@sswOrd1234"                                     #key pair for the SSH or RDP Connection  
  associate_public_ip_address = true
  user_data = file("userdata.tpl")
  security_groups = [aws_security_group.custom-ec2-sg.id]
}


# Define Autoscaling Group 
resource "aws_autoscaling_group" "web-server-ASGroup" {
  availability_zones        = ["us-east-1a"]
  name                      = "RHEL-ASG"
  depends_on = [aws_launch_configuration.RHEL-LC]
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 100
  health_check_type         = "EC2"
  force_delete              = true
  tag {
    key = "name"
    value = "Custom Ec2 Instance from ASG"
    propagate_at_launch = true
  }
  termination_policies = ["OldestInstance"]
  vpc_zone_identifier = [aws_subnet.AZ-1a-private_subnets.id,aws_subnet.AZ-1b-private_subnets.id]
  launch_configuration = aws_launch_configuration.RHEL-LC.name
  target_group_arns = [aws_lb_target_group.custom-ELB-TG.arn]

}

#define autoscaling configueration Policy 
resource "aws_autoscaling_policy" "custom-cpu-policy" {
  name = custom-cpu-policy
  autoscaling_group_name = aws_autoscaling_group.web-server-ASGroup.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown = 300
  policy_type = "SimpleScaling"
}

#define Cloudwatch Monitoring
resource "aws_cloudwatch_metric_alarm" "custom-cpu-alarm" {
  alarm_name = "custom-cpu-alarm"
  alarm_description = "alarm when the cpu usage increases"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = 50
  dimensions = {
    "AutoScalingGroupName" : aws_autoscaling_group.web-server-ASGroup.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.custom-cpu-policy.arn]
}

#define auto Descaling Policy
resource "aws_autoscaling_policy" "custom-cpu-policy-scaledown" {
  name = "custom-cpu-policy-scaledown"
  autoscaling_group_name = aws_autoscaling_group.web-server-ASGroup.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = -1
  policy_type = "SimpleScaling"
}

#define Descaling Cloud watch
resource "aws_cloudwatch_metric_alarm" "custom-cpu-alarm-scaledown" {
  alarm_name = "custom-cpu-alarm-scaledown"
  alarm_description = "alarm when the cpu usage decreases"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = 10
  dimensions = {
    "AutoScalingGroupName" : aws_autoscaling_group.web-server-ASGroup.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.custom-cpu-policy-scaledown.arn]
}