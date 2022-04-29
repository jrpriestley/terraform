output "instances" {
  value = {
    for v in azurerm_windows_virtual_machine.vm : v.name => v
  }
}