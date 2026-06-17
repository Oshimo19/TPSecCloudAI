# Terraform keys.tf
# ...

resource "aws_key_pair" "bastion" {
  key_name   = "${local.prefix}-key-bastion"
  public_key = file("~/.ssh/td-j2-key-bastion.pub")
}

resource "aws_key_pair" "private" {
  key_name   = "${local.prefix}-key-private"
  public_key = file("~/.ssh/td-j2-key-private.pub")
}

resource "aws_key_pair" "sonde" {
  key_name   = "${local.prefix}-key-sonde"
  public_key = file("~/.ssh/td-j2-key-sonde.pub")
}
