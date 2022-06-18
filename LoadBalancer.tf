resource "aws_lb_target_group" "custom-ELB-TG" {
  name     = "custom-ELB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = [aws_vpc.sharif.id]
}

#aws ELB config
resource "aws_elb" "custom-ELB" {
    name = "custom-ELB"
    subnets = [aws_subnet.AZ-1a-private_subnets.id,aws_subnet.AZ-1b-private_subnets.id]
    security_groups = [aws_security_group.custom-elb-sg.id]

    listener {
      instance_port = 80
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
    }

     health_check {
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 3
        target              = "HTTP:80/"
        interval            = 30
    }
    cross_zone_load_balancing = true
    connection_draining = true
    connection_draining_timeout = 400

    tag = {
      name = "Custom-ELB"
    }

}
#security Group for AWS ELB
resource "aws_security_group" "custom-elb-sg" {
    name = "custom-elb-sg"
    vpc_id = aws_vpc.sharif.id
    description = "Security group for elastic load balancer"
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
    protocol = "80"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tag {
      name = "Custom ELB security Group "
    }
}

