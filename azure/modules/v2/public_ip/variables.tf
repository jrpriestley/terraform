variable "public_ips" {
  type = list(object(
    {
      allocation_method = string
      name              = string
      resource_group    = string
      sku               = string
      availability_zone = optional(string)
      tags              = map(string)
    }
  ))
}