output "instances" {
  value = {
    for v in azurerm_linux_virtual_machine.vm : v.name => v
  }
}