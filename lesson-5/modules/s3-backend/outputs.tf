output "bucket_url" {
  value = aws_s3_bucket.tf_state.bucket
}

output "table_name" {
  value = aws_dynamodb_table.tf_locks.name
}
