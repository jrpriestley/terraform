output "freeipa_bastion" {
  value = {
    for k, v in module.instance-bastion.instances : k => v.public_ip
  }
}

output "freeipa_clients" {
  value = {
    for k, v in module.instance-clients.instances : k => v.private_ip
  }
}

output "freeipa_hosts" {
  value = {
    for k, v in module.instance-hosts.instances : k => v.private_ip
  }
}

output "freeipa_mgmt" {
  value = {
    for k, v in module.instance-mgmt.instances : k => v.public_ip
  }
}