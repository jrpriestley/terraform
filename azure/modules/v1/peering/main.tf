locals {
  peers = toset(flatten([
    for k1, v1 in var.peers : [
      for v2 in v1.peers : {
        vnet_a = k1
        vnet_b = v2
      }
    ]
  ]))
}

data "azurerm_virtual_network" "vnet" {
  for_each = { for k, v in var.peers : k => v }

  name                = each.key
  resource_group_name = each.value.resource_group
}

resource "azurerm_virtual_network_peering" "peer" {
  for_each = { for k, v in local.peers : format("%s_%s", v.vnet_a, v.vnet_b) => v }

  name                      = format("peer-%s-to-%s", each.value.vnet_a, each.value.vnet_b)
  resource_group_name       = data.azurerm_virtual_network.vnet[each.value.vnet_a].resource_group_name
  virtual_network_name      = each.value.vnet_a
  remote_virtual_network_id = data.azurerm_virtual_network.vnet[each.value.vnet_b].id
}