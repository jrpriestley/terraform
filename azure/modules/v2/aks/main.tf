locals {
  node_pools = toset(flatten([
    for i in range(length(var.node_pools)) : {
      index      = i
      node_count = values(var.node_pools)[i].node_count
      pool_name  = keys(var.node_pools)[i]
      tags       = values(var.node_pools)[i].tags
      vm_size    = values(var.node_pools)[i].vm_size
    }
  ]))
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

data "azurerm_subnet" "snet" {
  resource_group_name  = var.network_profile.pod_subnet_resource_group
  name                 = var.network_profile.pod_subnet
  virtual_network_name = var.network_profile.pod_subnet_virtual_network
}

resource "azurerm_user_assigned_identity" "identity" {
  count = var.identity == "UserAssigned" ? 1 : 0

  name                = var.name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group
  dns_prefix          = var.dns_prefix

  # The first pool in the map will be the default pool
  default_node_pool {
    name           = keys(var.node_pools)[0]
    node_count     = var.node_pools[keys(var.node_pools)[0]].node_count
    vm_size        = var.node_pools[keys(var.node_pools)[0]].vm_size
    vnet_subnet_id = data.azurerm_subnet.snet.id
    tags = merge(
      {
        terraform_managed = "true"
      },
      var.node_pools[keys(var.node_pools)[0]].tags
    )
  }

  identity {
    type                      = var.identity
    user_assigned_identity_id = var.identity == "UserAssigned" ? azurerm_user_assigned_identity.identity[var.name].id : null
  }

  network_profile {
    dns_service_ip     = var.network_profile.dns_service_ip
    docker_bridge_cidr = var.network_profile.docker_bridge_cidr
    network_plugin     = var.network_profile.network_plugin
    network_policy     = var.network_profile.network_policy
    pod_cidr           = var.network_profile.network_plugin == "kubenet" ? data.azurerm_subnet.snet[var.network_profile.pod_subnet].address_prefix : null
    service_cidr       = var.network_profile.service_cidr
  }

  tags = merge(
    {
      terraform_managed = "true"
    },
    var.tags
  )
}

resource "azurerm_kubernetes_cluster_node_pool" "aks-pool" {
  for_each = { for k, v in local.node_pools : v.pool_name => v if v.index > 0 } # Ignore the first pool in the map as we created that as the default pool

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  node_count            = each.value.node_count
  vm_size               = each.value.vm_size
  vnet_subnet_id        = data.azurerm_subnet.snet.id

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}