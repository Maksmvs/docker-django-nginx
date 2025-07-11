terraform {
  backend "s3" {
    bucket         = "YOUR_BUCKET_NAME"
    key            = "terraform/state/ci-cd"
    region         = "eu-central-1"
    dynamodb_table = "YOUR_DYNAMODB_NAME"
    encrypt        = true
  }
}
