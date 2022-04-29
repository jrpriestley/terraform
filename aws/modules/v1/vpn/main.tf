/* data "aws_route_table" "route_table" {
  for_each = toset(var.vpn.propagate_to)

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

*/

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_customer_gateway" "cgw" {
  bgp_asn    = var.gateway_remote.bgp_asn
  ip_address = var.gateway_remote.ip_address
  type       = "ipsec.1"

  tags = merge(
    {
      Name              = var.gateway_remote.name
      terraform_managed = "true"
    },
    var.gateway_remote.tags
  )
}

resource "aws_vpn_connection" "vpn" {
  customer_gateway_id   = aws_customer_gateway.cgw.id
  tunnel1_preshared_key = var.vpn.preshared_key
  static_routes_only    = true
  type                  = "ipsec.1"
  vpn_gateway_id        = aws_vpn_gateway.vgw.id

  tags = merge(
    {
      Name              = var.vpn.name
      terraform_managed = "true"
    },
    var.vpn.tags
  )
}

resource "aws_vpn_connection_route" "route" {
  for_each = toset(var.vpn.routes)

  destination_cidr_block = each.value
  vpn_connection_id      = aws_vpn_connection.vpn.id
}

resource "aws_vpn_gateway" "vgw" {
  vpc_id = data.aws_vpc.vpc.id

  tags = merge(
    {
      Name              = var.gateway_local.name
      terraform_managed = "true"
    },
    var.gateway_local.tags
  )
}

/*
  // Changed by Anand Stop Route Propagation This may have to be fixed or re done

resource "aws_vpn_gateway_route_propagation" "route_propagation" {
  for_each = toset(var.vpn.propagate_to)

  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = data.aws_route_table.route_table[each.value].id
}
*/
