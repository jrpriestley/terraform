variable "virtual_machines" {
  type = map(object(
    {
      image = object(
        {
          publisher = string
          offer     = string
          sku       = string
          version   = string
        }
      )
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