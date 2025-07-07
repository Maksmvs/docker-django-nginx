terraform {
  backend "s3" {
    bucket         = "your-s3-bucket-name"
    key            = "lesson-7/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "your-lock-table"
  }
}
