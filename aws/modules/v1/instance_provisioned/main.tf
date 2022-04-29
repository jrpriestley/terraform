data "aws_ami" "ami" {
  for_each = var.instances

  most_recent = true

  filter {
    name   = "name"
    values = [each.value.ami_name]
  }

  owners = [each.value.ami_owner]
}

data "aws_instance" "instance" {
  for_each = toset([for k, v in var.instances : v.provision_connect.host if v.provision_connect.host != "self"])

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

data "aws_security_group" "sg" {
  for_each = var.instances

  tags = {
    Name = each.value.security_group
  }
}

data "aws_subnet" "subnet" {
  for_each = var.instances

  tags = {
    Name = each.value.subnet
  }
}

resource "aws_network_interface" "nic" {
  for_each = var.instances

  subnet_id       = data.aws_subnet.subnet[each.key].id
  security_groups = [data.aws_security_group.sg[each.key].id]

  tags = {
    Name              = each.key
    terraform_managed = "true"
  }
}

resource "aws_instance" "instance" {
  for_each = var.instances

  ami           = data.aws_ami.ami[each.key].id
  instance_type = each.value.size
  key_name      = each.value.key_pair

  network_interface {
    network_interface_id = aws_network_interface.nic[each.key].id
    device_index         = 0
  }

  tags = merge(
    {
      Name              = each.key
      terraform_managed = "true"
    },
    each.value.tags
  )

  connection {
    bastion_host = each.value.provision_connect.host == "self" ? self.public_ip : data.aws_instance.instance[each.value.provision_connect.host].public_ip
    host         = self.private_ip
    private_key  = file(each.value.provision_connect.host_private_key)
    type         = "ssh"
    user         = each.value.provision_connect.host_user
  }

  provisioner "file" {
    source      = each.value.provision_file.source
    destination = each.value.provision_file.destination
  }

  provisioner "remote-exec" {
    script = each.value.provision_script
  }
}