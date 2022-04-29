output "ansible_clients_instantiated" {
  value = {
    for k, v in module.instance-ansible_clients.instances : k => v.private_ip
  }
}

output "ansible_clients_managed" {
  value = {
    for k, v in module.ansible.clients : k => v
  }
}

output "ansible_hosts" {
  value = {
    for k, v in module.instance-ansible_hosts.instances : k => v.private_ip
  }
}

output "bastion_instances" {
  value = {
    for k, v in module.instance-bastion.instances : k => v.public_ip
  }
}