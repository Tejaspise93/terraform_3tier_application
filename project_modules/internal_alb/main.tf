resource "aws_lb" "internal_alb" {
  name               = var.internal_alb_name
  internal           = true
  load_balancer_type = var.load_balancer_type
  subnets            = var.private_subnet_ids
  security_groups    = [var.internal_alb_sg_id]

    tags = {
    Name = var.internal_alb_name
  }

}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = "8080"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

    tags = {
    Name = "app-target-group"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
