output "clients" {
  value = {
    for v in var.clients : v => data.aws_instance.client[v].private_ip
  }
}