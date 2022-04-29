variable "peers" {
  type = map(object(
    {
      resource_group = string
      peers          = list(string)
    }
  ))
}