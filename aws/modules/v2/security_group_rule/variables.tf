variable "security_group_rules" {
  type = list(object(
    {
      security_group = string
      egress = list(object(
        {
          description = string
          endpoints   = list(string)
          from_port   = number
          protocol    = string
          to_port     = number
        }
      ))
      ingress = list(object(
        {
          description = string
          endpoints   = list(string)
          from_port   = number
          protocol    = string
          to_port     = number
        }
      ))
    }
  ))
}

variable "vpc" {
  type        = string
  description = "VPC for the security group rules to reside in"
}