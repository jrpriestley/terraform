output "key_pair_id" {
  value = aws_key_pair.key.id
}

output "key_pair_name" {
  value = aws_key_pair.key.key_name
}