resource "aws_security_group" "fp-alb-sg" {
  name = "fp-app-alb"
  description = "control access to the application load balancer"
  vpc_id = aws_vpc.fp-vpc.id

  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "fp-ecs-sg" {
  name = "fp-app-ecs-from-alb"
  description = "control access to the ecs cluster"
  vpc_id = aws_vpc.fp-vpc.id

  ingress {
    from_port = var.flask_app_port
    protocol = "TCP"
    to_port = var.flask_app_port
    security_groups = [aws_security_group.fp-alb-sg.id]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "fp-alb" {
  load_balancer_type = "application"
  name = "fp-alb"
  subnets = aws_subnet.fp-public-subnets.*.id
  security_groups = [aws_security_group.fp-alb-sg.id]
}

resource "aws_alb_target_group" "fp-target-group" {
  name = "fp-ecs-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.fp-vpc.id
  target_type = "ip"
}

resource "aws_alb_listener" "fp-alb-listener" {
  load_balancer_arn = aws_alb.fp-alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.fp-target-group.arn
    type = "forward"
  }
}

