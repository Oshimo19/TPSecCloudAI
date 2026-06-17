# Terraform keys.tf

resource "aws_key_pair" "web" {
  key_name   = "${local.prefix}-key-bastion"
  public_key = file("~/.ssh/td-j3-key-web.pub")
}

resource "aws_key_pair" "app" {
  key_name   = "${local.prefix}-key-app"
  public_key = file("~/.ssh/td-j3-key-app.pub")
}
