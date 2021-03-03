data "aws_security_group" "from_names" {
  for_each = toset(var.security_group_names)
  name     = each.value
}
