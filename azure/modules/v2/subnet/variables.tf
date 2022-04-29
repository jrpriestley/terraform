variable "subnets" {
  type = list(object(
    {
      resource_group  = string
      subnets         = map(list(string))
      virtual_network = string
    }
  ))
}