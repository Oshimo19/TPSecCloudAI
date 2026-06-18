resource "aws_lb" "internal" {
  name               = "${var.project_prefix}-alb-int"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_internal.id]
  subnets            = local.selected_subnet_ids

  tags = {
    Name = "${var.project_prefix}-alb-internal"
    Tier = "app"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_prefix}-tg-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_prefix}-tg-app"
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

resource "aws_instance" "app" {
  count = length(local.selected_subnet_ids)

  ami                    = var.vm_image
  instance_type          = var.vm_instance_type
  subnet_id              = local.selected_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = templatefile("${path.module}/app/user_data.sh.tpl", {
    app_py_b64  = base64encode(file("${path.module}/app/app.py"))
    db_host     = aws_db_instance.postgres.address
    db_name     = var.db_name
    db_user     = var.db_username
    db_password = var.db_password
  })

  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_prefix}-app-${count.index}"
    Tier = "app"
  }

  depends_on = [aws_db_instance.postgres]
}

resource "aws_lb_target_group_attachment" "app" {
  count = length(local.selected_subnet_ids)

  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}
