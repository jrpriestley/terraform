variable "virtual_networks" {
  type = list(object(
    {
      cidrs          = list(string)
      location       = optional(string)
      name           = string
      resource_group = string
      tags           = map(string)
    }
  ))
}