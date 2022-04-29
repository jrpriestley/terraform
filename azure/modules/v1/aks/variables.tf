variable "clusters" {
  type = map(object(
    {
      dns_prefix = string
      identity   = string
      network_profile = object(
        {
          dns_service_ip             = string
          docker_bridge_cidr         = string
          network_plugin             = string
          network_policy             = string
          pod_subnet_resource_group  = string
          pod_subnet_virtual_network = string
          pod_subnet                 = string
          service_cidr               = string
        }
      )
      node_pools = map(object(
        {
          node_count = number
          vm_size    = string
          tags       = map(string)
        }
      ))
      resource_group = string
      tags           = map(string)
    }
  ))
}

variable "container_registries" {
  type = map(object(
    {
      clusters       = list(string)
      resource_group = string
      sku            = string
      tags           = map(string)
    }
  ))
}