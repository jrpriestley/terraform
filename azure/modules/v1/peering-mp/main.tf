locals {
  peerings = toset(flatten([
    for k1, v1 in var.peerings : [
      for v2 in v1.src : [
        for v3 in v1.dst : {
          bidirectional_peering = v1.bidirectional_peering
          src                   = v2
          dst                   = v3
        }
      ]
    ]
  ]))
}

data "azurerm_virtual_network" "vnet-dst" {
  for_each = toset(flatten([for k1, v1 in var.peerings : [for v2 in v1.dst : v2]]))

  provider            = azurerm.dst
  name                = split("/", each.value)[1]
  resource_group_name = split("/", each.value)[0]
}

data "azurerm_virtual_network" "vnet-src" {
  for_each = toset(flatten([for k1, v1 in var.peerings : [for v2 in v1.src : v2]]))

  provider            = azurerm.src
  name                = split("/", each.value)[1]
  resource_group_name = split("/", each.value)[0]
}

resource "azurerm_virtual_network_peering" "peering-dst" {
  for_each = { for k, v in local.peerings : format("%s_%s", split("/", v.dst)[1], split("/", v.src)[1]) => v if v.bidirectional_peering == true }

  provider                  = azurerm.dst
  name                      = format("peer-%s-to-%s", split("/", each.value.dst)[1], split("/", each.value.src)[1])
  resource_group_name       = data.azurerm_virtual_network.vnet-dst[each.value.dst].resource_group_name
  virtual_network_name      = split("/", each.value.dst)[1]
  remote_virtual_network_id = data.azurerm_virtual_network.vnet-src[each.value.src].id
}

resource "azurerm_virtual_network_peering" "peering-src" {
  for_each = { for k, v in local.peerings : format("%s_%s", split("/", v.src)[1], split("/", v.dst)[1]) => v }

  provider                  = azurerm.src
  name                      = format("peer-%s-to-%s", split("/", each.value.src)[1], split("/", each.value.dst)[1])
  resource_group_name       = data.azurerm_virtual_network.vnet-src[each.value.src].resource_group_name
  virtual_network_name      = split("/", each.value.src)[1]
  remote_virtual_network_id = data.azurerm_virtual_network.vnet-dst[each.value.dst].id
}