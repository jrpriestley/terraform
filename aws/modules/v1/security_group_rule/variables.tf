variable "security_group_rules" {
  type = map(map(list(object(
    {
      description = string
      endpoints   = list(string)
      from_port   = number
      protocol    = string
      to_port     = number
    }
  ))))
}

variable "vpc" {
  type = string
}