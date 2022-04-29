data "azurerm_resource_group" "rg" {
  for_each = toset([for k, v in var.public_ips : v.resource_group])

  name = each.value
}

resource "azurerm_public_ip" "pip" {
  for_each = var.public_ips

  name                = each.key
  resource_group_name = each.value.resource_group
  allocation_method   = title(each.value.allocation_method)
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location
  sku                 = title(each.value.sku)

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}