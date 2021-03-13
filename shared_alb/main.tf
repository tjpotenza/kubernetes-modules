################################################################################
# The ALB itself
################################################################################
resource "aws_lb" "alb" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = concat(
    values(data.aws_security_group.from_names).*.id,
    [aws_security_group.upstream.id],
    var.security_group_ids,
  )
  subnets            = local.subnet_ids
}

################################################################################
# Listeners (One per port / protocol)
################################################################################
resource "aws_lb_listener" "ingress_443" {
  load_balancer_arn = aws_lb.alb.arn
  certificate_arn   = var.certificate_arn
  port              = "443"
  protocol          = "HTTPS"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "ingress_80" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
