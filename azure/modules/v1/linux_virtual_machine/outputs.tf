output "instances" {
  value = {
    for o in azurerm_linux_virtual_machine.vm : o.name => o
  }
}