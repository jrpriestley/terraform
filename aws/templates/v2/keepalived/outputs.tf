output "instances_bastion" {
  value = {
    for k, v in module.instance-bastion.instances : k => v.public_ip
  }
}

output "instances_backend" {
  value = {
    for k, v in module.instance-backend.instances : k => v.private_ip
  }
}