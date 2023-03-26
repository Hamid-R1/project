# target group
resource "aws_lb_target_group" "wp_tg" {
  target_type = "instance"
  name        = "pr8-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.wp_vpc.id

  stickiness { #here no need to enabled this stickiness argument,#
    #enabled = true
    enabled         = false
    type            = "lb_cookie"
    cookie_duration = 3600
  }

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
  }

}


# aws_lb_target_group_attachment 
resource "aws_lb_target_group_attachment" "instances-attachment-1" {
  target_group_arn = aws_lb_target_group.wp_tg.arn
  target_id        = aws_instance.wp-app-server-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instances-attachment-2" {
  target_group_arn = aws_lb_target_group.wp_tg.arn
  target_id        = aws_instance.wp-app-server-2.id
  port             = 80
}


# ALP
resource "aws_lb" "wp_alb" {
  name                       = "pr8-alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = [aws_subnet.wp-public-subnet-1.id, aws_subnet.wp-public-subnet-2.id]
  security_groups            = [aws_security_group.wp-ALB-SG.id]
  enable_deletion_protection = false
  /* "enable_deletion_protection" If true, deletion of the load balancer will be disabled via 
  the AWS API. This will prevent Terraform from deleting the load balancer.*/
}


# Load Balancer Listener
resource "aws_lb_listener" "alb_forward_listener" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}


/*
# Load Balancer Listener (on SSL 443 'https')
resource "aws_lb_listener" "front_end-443" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}
*/

