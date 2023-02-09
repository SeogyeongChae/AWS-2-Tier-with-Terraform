# aws_key_pair 설정
resource "aws_key_pair" "large" {
  key_name   = "large"
  public_key = file("large.pub")
}
# image 설정
data "aws_ami" "amzlinux" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
# security group 설정
resource "aws_security_group" "web" {
  name_prefix = var.security_group_name
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from VPC"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_http_ssh_instance"
  }
}
# public instance 설정
resource "aws_instance" "web_pub" {
  ami                         = data.aws_ami.amzlinux.image_id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.web.id]
  user_data_replace_on_change = true
  subnet_id                   = aws_subnet.pub_c.id
  key_name                    = aws_key_pair.large.id
  depends_on                  = [aws_db_instance.tf-db]
  user_data = templatefile("userdata.tftpl", {
    port_number = var.server_port
		db_endpoint = aws_db_instance.tf-db.endpoint
  })

  tags = {
    Name = "large-web-pub"
  }
}
# own AMI 설정
resource "aws_ami_from_instance" "web-img" {
  name               = "large-img"
  source_instance_id = aws_instance.web_pub.id # "i-0d372b56a1ab5ce55"
  tags = {
      Name = "web-"
	}
}
# autoscaling AMI 설정
resource "aws_launch_configuration" "web" {
  name_prefix = "lc-web-"
  image_id    = aws_ami_from_instance.web-img.id # (var.image_id, data.aws_ami.amzLinux.id)
  instance_type   = var.instance_type
  security_groups = [aws_security_group.web.id]
  key_name        = aws_key_pair.large.key_name
  depends_on      = [aws_ami_from_instance.web-img]
  user_data = templatefile("userdata.tftpl", {
    port_number = var.server_port
  })

  lifecycle {
    create_before_destroy = true
  }
}
# 이미지 ID는 생성한 이미지를 적어줍니다.

# autoscaling group 설정
resource "aws_autoscaling_group" "web" {
  name_prefix          = "aws-web-"
  launch_configuration = aws_launch_configuration.web.name
  vpc_zone_identifier  = [aws_subnet.pri_a.id, aws_subnet.pri_c.id]

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "large-asg-web"
    propagate_at_launch = true
  }
}
# vpc_zone_identifier에는 프라이빗 서브넷을 지정해줍니다.

# ALB security group 설정
resource "aws_security_group" "alb" {
  name        = var.alb_security_group_name
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP from VPC"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}
# LB 설정
resource "aws_lb" "alb" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = [aws_subnet.pub_a.id, aws_subnet.pub_c.id]
  security_groups    = [aws_security_group.alb.id]
}

variable "alb_name" {
  description = "The name of the ALB"
  type        = string
  default     = "large-alb"
}
# Subnets에는 퍼블릭의 서브넷을 지정해줍니다.

# lb listener 설정
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found\n"
      status_code  = 404
    }
  }
}
# lb target group 설정
resource "aws_lb_target_group" "asg" {
  name_prefix = "alb-"
  port        = 80
  protocol    = "HTTP"
	deregistration_delay = 60
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
# aws_lb listerner rule 설정
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}