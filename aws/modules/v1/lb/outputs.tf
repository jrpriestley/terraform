output "load_balancers" {
  value = {
    for lb in aws_lb.lb : lb.name => lb.dns_name
  }
}