variable "virtual_networks" {
  type = list(object(
    {
      cidrs          = list(string)
      name           = string
      resource_group = string
      tags           = map(string)
    }
  ))
}