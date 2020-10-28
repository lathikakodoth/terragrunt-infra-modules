terraform {
  required_version = "= 0.13.4"


  required_providers {
    aws ={
      source ="hasicorp/aws"
      version = "= 3.7.0"
    }
  }
}

resource "aws_security_group" "asg" {
  name = "${var.name}-asg"
}
resource "aws_security_group_rule" "asg_inbound_rule" {
  type              = "ingress"
  from_port         = var.server_port
  to_port           =  var.server_port
  protocol          = "tcp"
  cidr_blocks       = [0.0.0.0/0]
  security_group_id = aws_security_group.asg.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }
  filter {
  name   = "architecture"
  values = ["x86_64"]
}

filter {
  name   = "image-type"
  values = ["machine"]
}

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "webserver" {
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.asg.id]

  user_data = <<-EOF
               #!/bin/bash
               echo "Hello, World" > index.html
               nohup busybox httpd -f -p "${var.server_port}" &
               EOF

  lifecycle {
  create_before_destroy = true
}
}

resource "aws_autoscaling_group" "webserver" {
  launch_configuration      = aws_launch_configuration.webserver.name
  vpc_zone_identifier       = data.aws_subnet_ids.default.ids

load_balancers  = [aws_elb.webserver.name]
health_check_type         = "ELB"
health_check_grace_period = 300

max_size                  = 5
min_size                  = 2
tag {
  key                 = "Name"
  value               = var.name
  propagate_at_launch = true
}


}


resource "aws_security_group" "elb" {
  name = "${var.name}-elb"
}

resource "aws_security_group_rule" "elb_allow_http_inbound" {
  type              = "ingress"
  from_port         = var.elb_port
  to_port           = var.elb_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb.id
}

resource "aws_security_group_rule" "elb_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb.id
}

resource "aws_elb" "webserver" {
  name               = var.name
  subnets         = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.elb.id]



  listener {
    instance_port     = var.server_port
    instance_protocol = "http"
    lb_port           = var.elb_port
    lb_protocol       = "http"
  }



  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:${var.server_port}/"
    interval            = 30
  }


}
