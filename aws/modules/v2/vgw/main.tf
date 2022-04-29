data "aws_route_table" "route_table" {
  for_each = toset(var.propagate_to)

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_vpn_gateway" "vgw" {
  vpc_id = data.aws_vpc.vpc.id

  tags = merge(
    {
      Name              = var.name
      terraform_managed = "true"
    },
    var.tags
  )
}

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  for_each = toset(var.propagate_to)

  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = data.aws_route_table.route_table[each.value].id
}