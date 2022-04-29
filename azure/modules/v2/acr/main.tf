data "azurerm_kubernetes_cluster" "aks" {
  for_each = toset(var.clusters)

  name                = each.value
  resource_group_name = var.resource_group
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

resource "azurerm_container_registry" "acr" {
  name                = var.name
  resource_group_name = var.resource_group
  location            = data.azurerm_resource_group.rg.location
  sku                 = var.sku

  tags = merge(
    {
      terraform_managed = "true"
    },
    var.tags
  )
}

# This resource requires either a custom role with role assignment privilege (preferred) or Owner permission on the account you are deploying with. For the CTLDisasterRecovery tenant, I had to use Owner since I do not have permission to create custom roles.
resource "azurerm_role_assignment" "ra" {
  for_each = toset(var.clusters)

  principal_id                     = data.azurerm_kubernetes_cluster.aks[each.value].kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}