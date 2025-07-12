# CI/CD Django App Pipeline

## Запуск Terraform

```bash
terraform init
terraform apply
```

## Jenkins

- URL: `terraform output jenkins_url`
- Логін: admin
- Пароль: з `terraform output` або values.yaml

## Jenkins Pipeline

- Збирає Docker-образ, пушить в ECR
- Оновлює Helm chart у Git
- Запускає Argo CD для деплою

## Argo CD

- URL: `terraform output argo_cd_url`
- Логін: admin
- Пароль: з kubectl (отримати через `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode`)

## Видалення

```bash
terraform destroy
```
