locals {
  subnets = toset(flatten([
    for k1, v1 in var.subnets : [
      for k2, v2 in v1.subnets : {
        cidrs = v2
        snet  = k2
        vnet  = k1
      }
    ]
  ]))
}

data "azurerm_virtual_network" "vnet" {
  for_each = var.subnets

  name                = each.key
  resource_group_name = each.value.resource_group
}

resource "azurerm_subnet" "subnet" {
  for_each = { for k, v in local.subnets : format("%s_%s", v.vnet, v.snet) => v }

  name                 = each.value.snet
  resource_group_name  = data.azurerm_virtual_network.vnet[each.value.vnet].resource_group_name
  virtual_network_name = each.value.vnet
  address_prefixes     = each.value.cidrs
}