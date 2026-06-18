# Terraform web_tier.tf
# ALB public + EC2 web + target group

resource "aws_lb" "public" {
  name               = "${local.prefix}-alb-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb_public.id]
  subnets            = aws_subnet.public[*].id

  tags = { Name = "${local.prefix}-alb-public" }
}

resource "aws_lb_target_group" "web" {
  name     = "${local.prefix}-tg-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "${local.prefix}-tg-web" }
}

resource "aws_lb_listener" "public_http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_instance" "web" {
  count                  = length(var.azs)
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.web[count.index].id
  vpc_security_group_ids = [aws_security_group.sg_web.id]

  user_data = templatefile("${path.module}/web/user_data.sh.tpl", {
    internal_alb_dns = aws_lb.internal.dns_name
    web_py_b64       = base64encode(file("${path.module}/web/web.py"))
    requirements_b64 = base64encode(file("${path.module}/web/requirements.txt"))
  })

  tags = {
    Name = "${local.prefix}-web-${count.index + 1}"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
