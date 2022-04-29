variable "bastion" {
  type = object(
    {
      host             = string
      host_private_key = string
      host_user        = string
    }
  )
}

variable "clients" {
  type = list(string)
}

variable "hosts" {
  type = list(string)
}

variable "template" {
  type = object(
    {
      in  = string
      out = string
    }
  )
}