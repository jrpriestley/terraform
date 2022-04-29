output "windows_virtual_machines" {
  value = {
    for k, v in module.windows_virtual_machine.instances : k => {
      resource_group_name  = v.resource_group_name
      private_ip_addresses = v.private_ip_addresses
      public_ip_addresses  = v.public_ip_addresses
    }
  }
}