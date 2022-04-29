output "instances" {
  value = {
    for o in aws_instance.instance : o.tags_all["Name"] => o
  }
}