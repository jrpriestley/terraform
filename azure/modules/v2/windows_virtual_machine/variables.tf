variable "virtual_machines" {
  type = list(object(
    {
      image = object(
        {
          publisher = string
          offer     = string
          sku       = string
          version   = string
        }
      )
      location       = optional(string)
      name           = string
      resource_group = string
      password       = string
      public_ip      = string
      size           = string
      subnet         = string
      username       = string
      tags           = map(string)
    }
  ))
}