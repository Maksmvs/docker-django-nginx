output "s3_bucket_url" {
  value = module.s3_backend.bucket_url
}

output "dynamodb_table_name" {
  value = module.s3_backend.table_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_url" {
  value = module.ecr.repository_url
}
