resource "azurerm_resource_group" "rg" {
  for_each = { for k, v in var.resource_groups : v.name => v }

  name     = each.key
  location = each.value.location

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}