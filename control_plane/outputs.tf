output "master_address" {
  value = local.master_address
}

output "cluster_member_security_group_id" {
  value = aws_security_group.cluster_member.id
}
