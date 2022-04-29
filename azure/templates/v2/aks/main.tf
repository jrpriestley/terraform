module "resource_group" {
  resource_groups = [
    {
      name     = "rg-${var.project_name}-01"
      location = "East US"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/resource_group"
}

module "virtual_network" {
  depends_on = [
    module.resource_group,
  ]

  virtual_networks = [
    {
      name           = "vnet-${var.project_name}-01"
      resource_group = "rg-${var.project_name}-01"
      cidrs          = ["10.10.0.0/16"]
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/virtual_network"
}

module "subnet" {
  depends_on = [
    module.virtual_network,
  ]

  subnets = [
    {
      name            = "vnet-${var.project_name}-01"
      resource_group  = "rg-${var.project_name}-01"
      virtual_network = "vnet-${var.project_name}-01"
      subnets = {
        public-01  = ["10.10.0.0/24"]
        private-01 = ["10.10.64.0/24"]
        aks-01     = ["10.10.128.0/22"]
      }
    },
  ]

  source = "../../../modules/v2/subnet"
}

module "network_security_group" {
  depends_on = [
    module.resource_group,
    module.subnet,
    module.virtual_network,
  ]

  network_security_groups = [
    {
      name                              = "nsg-${var.project_name}-01-private-01"
      resource_group                    = "rg-${var.project_name}-01"
      virtual_network                   = "vnet-${var.project_name}-01"
      subnets                           = ["private-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      tags = {
      }
    },
    {
      name                              = "nsg-${var.project_name}-01-public-01"
      resource_group                    = "rg-${var.project_name}-01"
      virtual_network                   = "vnet-${var.project_name}-01"
      subnets                           = ["public-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/network_security_group"
}

module "aks-01" {
  depends_on = [
    module.network_security_group,
    module.resource_group,
    module.subnet,
  ]

  name           = "aks-${var.project_name}-01"
  dns_prefix     = "aks${var.project_name}01"
  identity       = "SystemAssigned"
  resource_group = "rg-${var.project_name}-01"
  network_profile = {
    dns_service_ip             = "10.20.0.4"
    docker_bridge_cidr         = "172.17.0.1/16"
    network_plugin             = "azure"
    network_policy             = "azure"
    pod_subnet_resource_group  = "rg-${var.project_name}-01"
    pod_subnet_virtual_network = "vnet-${var.project_name}-01"
    pod_subnet                 = "aks-01"
    service_cidr               = "10.20.0.0/16"
  }
  node_pools = {
    system = {
      node_count = 3
      vm_size    = "Standard_D2_v2"
      tags = {
      }
    }
    user01 = {
      node_count = 3
      vm_size    = "Standard_D2_v2"
      tags = {
      }
    }
  }
  tags = {
  }

  source = "../../../modules/v2/aks"
}

module "acr-01" {
  depends_on = [
    module.resource_group,
  ]

  name           = "acr${var.project_name}01"
  resource_group = "rg-${var.project_name}-01"
  clusters       = ["aks-${var.project_name}-01"]
  sku            = "basic"
  tags = {
  }

  source = "../../../modules/v2/acr"
}