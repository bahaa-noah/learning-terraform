resource "aws_elb" "this" {
  name            = "${var.web_app}-web"
  subnets         = var.subnets
  security_groups = var.security_groups
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  tags = {
    "Terraform" = "true"
  }
}


resource "aws_launch_configuration" "this" {
  name_prefix   = "${var.web_app}-web"
  image_id      = var.web_image_id
  instance_type = var.web_instance_type

  security_groups = [aws_security_group.prod_web.id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  min_size             = var.web_min_size
  max_size             = var.web_max_size
  desired_capacity     = var.web_desired_capacity
  launch_configuration = aws_launch_configuration.this.id
  vpc_zone_identifier  = var.subnets
  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.web_app}-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  alb_target_group_arn   = aws_lb_target_group.this.arn
}
