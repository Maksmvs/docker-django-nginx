output "rds_instance_endpoint" {
  value       = aws_db_instance.this[0].address
  description = "Endpoint of RDS instance"
  condition   = !var.use_aurora
}

output "aurora_cluster_endpoint" {
  value       = aws_rds_cluster.this[0].endpoint
  description = "Writer endpoint of Aurora cluster"
  condition   = var.use_aurora
}

