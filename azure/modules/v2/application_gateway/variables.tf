variable "backend" {
  type = object(
    {
      cookie_based_affinity = string
      members               = list(string)
      port                  = number
      protocol              = string
      request_timeout       = number
    }
  )
  default = {
    cookie_based_affinity = "Disabled"
    members               = []
    port                  = "80"
    protocol              = "Http"
    request_timeout       = 60
  }
  description = "Backend configuration for the application gateway"
}

variable "frontend" {
  type = object(
    {
      ip       = string
      port     = number
      protocol = string
    }
  )
  description = "Frontend configuration for the application gateway"
}

variable "name" {
  type        = string
  description = "Application gateway name"
}

variable "resource_group" {
  type        = string
  description = "Resource group to provision into"
}

variable "sku" {
  type = object(
    {
      name     = string
      tier     = string
      capacity = number
    }
  )
  description = "Application gateway SKU"
}

variable "subnet" {
  type        = string
  description = "Subnet to attach the frontend of the application gateway to"
}

variable "tags" {
  type = map(string)
}