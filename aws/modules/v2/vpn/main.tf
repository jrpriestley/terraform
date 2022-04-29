data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

data "aws_vpn_gateway" "vgw" {
  tags = {
    Name = var.gateway_local
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
  vpn_gateway_id        = data.aws_vpn_gateway.vgw.id

  tags = merge(
    {
      Name              = var.vpn.name
      terraform_managed = "true"
    },
    var.vpn.tags
  )

  lifecycle {
    ignore_changes = [
      tunnel1_dpd_timeout_action,
      tunnel1_ike_versions,
      tunnel1_phase1_dh_group_numbers,
      tunnel1_phase1_encryption_algorithms,
      tunnel1_phase1_integrity_algorithms,
      tunnel1_phase2_dh_group_numbers,
      tunnel1_phase2_encryption_algorithms,
      tunnel1_phase2_integrity_algorithms,
      tunnel1_startup_action,
      tunnel2_dpd_timeout_action,
      tunnel2_ike_versions,
      tunnel2_phase1_dh_group_numbers,
      tunnel2_phase1_encryption_algorithms,
      tunnel2_phase1_integrity_algorithms,
      tunnel2_phase2_dh_group_numbers,
      tunnel2_phase2_encryption_algorithms,
      tunnel2_phase2_integrity_algorithms,
      tunnel2_startup_action,
      vgw_telemetry,
      vpn_gateway_id,
    ]
  }
}

resource "aws_vpn_connection_route" "route" {
  for_each = toset(var.vpn.routes)

  destination_cidr_block = each.value
  vpn_connection_id      = aws_vpn_connection.vpn.id
}