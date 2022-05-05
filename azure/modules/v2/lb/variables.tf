variable "backend_address_pools" {
  type = list(object(
    {
      name = string
      addresses = list(object(
        {
          ip_address = string
          name       = string
          vnet       = string
        }
      ))
    }
  ))
}

variable "frontend_ip_configuration" {
  type = object(
    {
      availability_zone             = optional(string)
      private_ip_address_allocation = optional(string)
      private_ip_address_version    = optional(string)
      public_ip                     = optional(string)
      subnet                        = optional(string)
    }
  )
}

variable "name" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "sku" {
  type = string
}