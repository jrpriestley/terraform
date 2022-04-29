variable "gateway_local" {
  type = object(
    {
      bgp_asn = number
      name    = string
      tags    = map(string)
    }
  )
}

variable "gateway_remote" {
  type = object(
    {
      bgp_asn    = number
      ip_address = string
      name       = string
      tags       = map(string)
    }
  )
}

variable "vpn" {
  type = object(
    {
      name               = string
      preshared_key      = string
      propagate_to       = list(string)
      routes             = list(string)
      static_routes_only = bool
      tags               = map(string)
    }
  )
}

variable "vpc" {
  type = string
}