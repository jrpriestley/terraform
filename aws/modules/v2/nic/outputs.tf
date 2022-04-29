output "nic" {
  value = {
    for v in aws_network_interface.nic : v.tags_all["Name"] => v
  }
}