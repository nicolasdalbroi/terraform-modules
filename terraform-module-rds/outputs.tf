output "global_cluster_identifier" {
  value = try(aws_rds_global_cluster.global_cluster[0].id, null)
}
output "primary_cluster_endpoint" {
  value = try(aws_rds_cluster.primary_cluster.endpoint)
}

output "secondary_cluster_endpoint" {
  value = try(aws_rds_cluster.secondary[0].endpoint, null)
}

output "database_subnet_ids" {
  description = "Map of AZ to database subnet ID"
  value       = { for k, v in aws_subnet.database_subnet : k => v.id }
}
