resource "aws_lb" "this" {
  name               = "${var.project}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = true
}

resource "aws_lb_listener" "lb_80" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_80.arn
  }

}

resource "aws_lb_target_group" "lb_80" {
  name        = "${var.project}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path    = "/"
    port    = "80"
  }

  depends_on = [aws_lb.this]
}


# SG to allow access only for port 3000
resource "aws_security_group" "load_balancer" {
  name        = "load-balancer-sg"
  description = "controls access to the ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.app_port
    to_port     = var.app_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}