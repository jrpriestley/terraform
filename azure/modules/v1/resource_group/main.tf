resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups

  name     = each.key
  location = each.value.location

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}