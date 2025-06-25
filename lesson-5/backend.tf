terraform {
  backend "s3" {
    bucket         = "docker-django-nginx-tf-state"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
