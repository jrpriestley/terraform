variable "instances" {
  type = map(object(
    {
      ami_name       = string
      ami_owner      = string
      key_pair       = string
      security_group = string
      size           = string
      subnet         = string
      tags           = map(string)
    },
  ))
}