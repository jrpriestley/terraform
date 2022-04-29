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
      name            = string
      resource_group  = string
      password        = string
      public_ip       = string
      size            = string
      subnet          = string
      username        = string
      virtual_network = string
      tags            = map(string)
    }
  ))
}