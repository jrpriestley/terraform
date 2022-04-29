variable "network_security_group_rules" {
  type = list(object(
    {
      security_group = string
      resource_group = string
      rules = map(list(object(
        {
          description = string
          priority    = number
          access      = string
          protocol    = string
          from_port   = list(string)
          to_port     = list(string)
          source      = list(string)
          destination = list(string)
        }
      )))
    }
  ))
}