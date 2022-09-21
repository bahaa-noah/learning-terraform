variable "whitelist" {
  type = list(string)
}
variable "web_image_id" {
  type = string
}
variable "web_instance_type" {
  type = string
}
variable "web_min_size" {
  type = number
}
variable "web_max_size" {
  type = number
}
variable "web_desired_capacity" {
  type = number
}

provider "aws" {
  profile = "terraform"
  region  = "me-central-1"
}

resource "aws_s3_bucket" "prod_tf_course" {
  bucket = "test-tf-course-20220916"
  acl    = "private"
}

resource "aws_default_vpc" "default" {}
resource "aws_default_subnet" "default_az1" {
  availability_zone = "me-central-1a"
  tags = {
    "Terraform" = "true"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "me-central-1b"
  tags = {
    "Terraform" = "true"
  }
}

resource "aws_security_group" "prod_web" {
  name        = "prod_web"
  description = "Allow standard http/s ports inbound  and everything outbound"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.whitelist

  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.whitelist
  }

  tags = {
    "Terraform" = "true"
  }
}

# resource "aws_instance" "prod_web" {
#   count                  = 2
#   ami                    = "ami-03ccfaecad4b0f79e"
#   instance_type          = "t3.micro"
#   vpc_security_group_ids = [aws_security_group.prod_web.id]

#   tags = {
#     "Terraform" = "true"
#   }
# }


# resource "aws_eip_association" "prod_web" {
#   instance_id   = aws_instance.prod_web.0.id
#   allocation_id = aws_eip.prod_web.id
# # }
# resource "aws_eip" "prod_web" {
#   tags = {
#     "Terraform" = "true"
#   }
# }


resource "aws_elb" "prod_web" {
  name = "prod-web"
  #   instances       = aws_instance.prod_web.*.id
  subnets         = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.prod_web.id]
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


resource "aws_launch_configuration" "prod_web" {
  name_prefix   = "prod-wb"
  image_id      = var.web_image_id
  instance_type = var.web_instance_type

  security_groups = [aws_security_group.prod_web.id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "prod_web" {
  min_size             = var.web_min_size
  max_size             = var.web_max_size
  desired_capacity     = var.web_desired_capacity
  launch_configuration = aws_launch_configuration.prod_web.id
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "prod_web" {
  name     = "prod-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  alb_target_group_arn   = aws_lb_target_group.prod_web.arn
}
