data "azurerm_resource_group" "rg" {
  for_each = { for k, v in var.keys : v.resource_group => v }

  name = each.value.resource_group
}

resource "azurerm_ssh_public_key" "key" {
  for_each = var.keys

  name                = each.key
  resource_group_name = each.value.resource_group
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location
  public_key          = file(each.value.public_key)
}