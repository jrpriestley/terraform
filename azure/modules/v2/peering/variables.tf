variable "peerings" {
  type = list(object(
    {
      bidirectional_peering = bool
      dst                   = list(string)
      src                   = list(string)
      use_remote_gateway    = bool
    }
  ))
}