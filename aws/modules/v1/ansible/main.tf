locals {
  clients = toset([
    for v in var.clients : "${data.aws_instance.client[v].private_ip} # id: ${data.aws_instance.client[v].id}; name: ${v}"
  ])
  hosts = toset(flatten([
    for v in var.hosts : {
      ip   = data.aws_instance.host[v].private_ip
      name = v
    }
  ]))
}

data "aws_instance" "bastion" {
  filter {
    name   = "tag:Name"
    values = [var.bastion.host]
  }
}

data "aws_instance" "client" {
  for_each = toset(var.clients)

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

data "aws_instance" "host" {
  for_each = toset(var.hosts)

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

resource "local_file" "inventory" {
  content = templatefile(var.template.in,
    {
      clients = local.clients
    }
  )
  filename = var.template.out
}

resource "null_resource" "inventory" {
  for_each = toset(var.hosts)

  triggers = {
    clients = join(",", local.clients)
  }

  connection {
    bastion_host = data.aws_instance.bastion.public_ip
    host         = data.aws_instance.host[each.value].private_ip
    private_key  = file(var.bastion.host_private_key)
    type         = "ssh"
    user         = var.bastion.host_user
  }

  provisioner "file" {
    source      = var.template.out
    destination = "/tmp/hosts"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/hosts /etc/ansible/hosts",
      "ansible -m ping clients",
      "ansible -m ansible.builtin.shell -a 'uname -a' clients",
    ]
  }
}