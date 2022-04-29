output "security_groups" {
  value = {
    for o in aws_security_group.sg : o.name => o
  }
}