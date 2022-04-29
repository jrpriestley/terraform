output "instances" {
  value = {
    for o in azurerm_windows_virtual_machine.vm : o.name => o
  }
}