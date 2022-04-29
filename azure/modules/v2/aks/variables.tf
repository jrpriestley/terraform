variable "dns_prefix" {
  type        = string
  description = "DNS prefix to use for the cluster"
}

variable "identity" {
  type        = string
  description = "Identity type to use, either SystemAssigned or UserAssigned"
}

variable "name" {
  type        = string
  description = "Cluster name"
}

variable "network_profile" {
  type = object(
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
}

variable "node_pools" {
  type = map(object(
    {
      node_count = number
      vm_size    = string
      tags       = map(string)
    }
  ))
}

variable "resource_group" {
  type        = string
  description = "Resource group to provision into"
}

variable "tags" {
  type = map(string)
}