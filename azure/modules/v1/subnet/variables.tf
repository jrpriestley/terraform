variable "subnets" {
  type = map(object(
    {
      resource_group = string
      subnets        = map(list(string))
    }
  ))
}