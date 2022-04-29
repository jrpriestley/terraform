locals {
  cluster_node_pools = toset(flatten([
    for k1, v1 in var.clusters : [
      for i in range(length(v1.node_pools)) : {
        index          = i
        cluster_id     = azurerm_kubernetes_cluster.cluster[k1].id
        node_count     = values(v1.node_pools)[i].node_count
        pool_name      = keys(v1.node_pools)[i]
        tags           = values(v1.node_pools)[i].tags
        vm_size        = values(v1.node_pools)[i].vm_size
        vnet_subnet_id = data.azurerm_subnet.snet[v1.network_profile.pod_subnet].id
      }
    ]
  ]))
  container_registries = toset(flatten([
    for k1, v1 in var.container_registries : [
      for v2 in v1.clusters : {
        acr          = k1
        cluster      = v2
        principal_id = azurerm_kubernetes_cluster.cluster[v2].kubelet_identity[0].object_id
        rg           = v1.resource_group
      }
    ]
  ]))
}

data "azurerm_resource_group" "rg" {
  for_each = toset([for k, v in var.clusters : v.resource_group])

  name = each.value
}

data "azurerm_subnet" "snet" {
  for_each = { for k, v in var.clusters : v.network_profile.pod_subnet => v.network_profile }

  resource_group_name  = each.value.pod_subnet_resource_group
  name                 = each.key
  virtual_network_name = each.value.pod_subnet_virtual_network
}

resource "azurerm_user_assigned_identity" "identity" {
  for_each = { for k, v in var.clusters : k => v if(v.identity == "UserAssigned") }

  name                = each.key
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location
  resource_group_name = each.value.resource_group
}

resource "azurerm_kubernetes_cluster" "cluster" {
  for_each = var.clusters

  name                = each.key
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location
  resource_group_name = each.value.resource_group
  dns_prefix          = each.value.dns_prefix

  # The first pool in the map will be the default pool
  default_node_pool {
    name           = keys(each.value.node_pools)[0]
    node_count     = each.value.node_pools[keys(each.value.node_pools)[0]].node_count
    vm_size        = each.value.node_pools[keys(each.value.node_pools)[0]].vm_size
    vnet_subnet_id = data.azurerm_subnet.snet[each.value.network_profile.pod_subnet].id
    tags = merge(
      {
        terraform_managed = "true"
      },
      each.value.node_pools[keys(each.value.node_pools)[0]].tags
    )
  }

  identity {
    type                      = each.value.identity
    user_assigned_identity_id = each.value.identity == "UserAssigned" ? azurerm_user_assigned_identity.identity[each.key].id : null
  }

  network_profile {
    dns_service_ip     = each.value.network_profile.dns_service_ip
    docker_bridge_cidr = each.value.network_profile.docker_bridge_cidr
    network_plugin     = each.value.network_profile.network_plugin
    network_policy     = each.value.network_profile.network_policy
    pod_cidr           = each.value.network_profile.network_plugin == "kubenet" ? data.azurerm_subnet.snet[each.value.network_profile.pod_subnet].address_prefix : null
    service_cidr       = each.value.network_profile.service_cidr
  }

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}

resource "azurerm_kubernetes_cluster_node_pool" "aks-pool" {
  for_each = { for k, v in local.cluster_node_pools : v.pool_name => v if v.index > 0 } # Ignore the first pool in the map as we created that as the default pool

  name                  = each.key
  kubernetes_cluster_id = each.value.cluster_id
  node_count            = each.value.node_count
  vm_size               = each.value.vm_size
  vnet_subnet_id        = each.value.vnet_subnet_id

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}

resource "azurerm_container_registry" "acr" {
  for_each = var.container_registries

  name                = each.key
  resource_group_name = each.value.resource_group
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location
  sku                 = each.value.sku

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}

# This resource requires either a custom role with role assignment privilege (preferred) or Owner permission on the account you are deploying with. For the CTLDisasterRecovery tenant, I had to use Owner since I do not have permission to create custom roles.
resource "azurerm_role_assignment" "ra-acr" {
  for_each = { for k, v in local.container_registries : format("%s_%s", v.acr, v.cluster) => v }

  principal_id                     = each.value.principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr[each.value.acr].id
  skip_service_principal_aad_check = true
}