# Terraform app_tier.tf
# ALB interne + EC2 app + target group

resource "aws_lb" "internal" {
  name               = "${local.prefix}-alb-internal"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb_internal.id]
  subnets            = aws_subnet.app[*].id

  tags = {
    Name = "${local.prefix}-alb-internal"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${local.prefix}-tg-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${local.prefix}-tg-app"
  }
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "app" {
  count                  = length(var.azs)
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.app[count.index].id
  vpc_security_group_ids = [aws_security_group.sg_app.id]
  key_name               = aws_key_pair.app.key_name

  tags = {
    Name = "${local.prefix}-app-${count.index + 1}"
  }

  depends_on = [aws_nat_gateway.nat]
}

resource "aws_lb_target_group_attachment" "app" {
  count            = length(aws_instance.app)
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}
