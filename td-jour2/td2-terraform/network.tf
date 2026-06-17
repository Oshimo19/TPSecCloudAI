# Terraform network.tf

resource "aws_subnet" "td2_subnets" {
  for_each                = var.subnets_cidr_block
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public

  tags = {
    Name = "${local.prefix}-subnet-${each.key}"
  }
}
