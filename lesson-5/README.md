# Terraform AWS Infrastructure (lesson-5)

Проєкт розміщено в репозиторії `docker-django-nginx` у папці `lesson-5`.

## Модулі:

- `s3-backend`: S3 + DynamoDB для збереження та блокування state
- `vpc`: створює VPC з публічними й приватними підмережами
- `ecr`: створює Docker-репозиторій у ECR

## Команди для запуску:

```bash
terraform init
terraform plan
terraform apply
terraform destroy
