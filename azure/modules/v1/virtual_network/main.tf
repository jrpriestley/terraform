data "azurerm_resource_group" "rg" {
  for_each = toset([for k, v in var.virtual_networks : v.resource_group])

  name = each.key
}

resource "azurerm_virtual_network" "vnet" {
  for_each = var.virtual_networks

  name                = each.key
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location
  resource_group_name = data.azurerm_resource_group.rg[each.value.resource_group].name
  address_space       = each.value.cidrs

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}