#!/bin/bash
set -e

# Створення каталогів
mkdir -p modules/s3-backend modules/vpc modules/ecr modules/eks modules/jenkins modules/argo_cd
mkdir -p charts/django-app/templates

# main.tf
cat > main.tf << EOF
module "s3_backend" {
  source = "./modules/s3-backend"
  bucket_name = "your-terraform-state-bucket"
  dynamodb_table_name = "terraform-lock-table"
  region = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"
  # додавай свої змінні
}

module "ecr" {
  source = "./modules/ecr"
  repository_name = "django-app-repo"
}

module "eks" {
  source = "./modules/eks"
  # додавай свої змінні
}

module "jenkins" {
  source = "./modules/jenkins"
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_cluster_ca = module.eks.cluster_ca
}

module "argo_cd" {
  source = "./modules/argo_cd"
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_cluster_ca = module.eks.cluster_ca
}
EOF

# backend.tf
cat > backend.tf << EOF
terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
EOF

# variables.tf
cat > variables.tf << EOF
variable "region" {
  type    = string
  default = "us-east-1"
}
EOF

# outputs.tf
cat > outputs.tf << EOF
output "jenkins_url" {
  value = module.jenkins.jenkins_url
}

output "argo_cd_url" {
  value = module.argo_cd.argo_cd_url
}
EOF

# Jenkinsfile
cat > Jenkinsfile << 'EOF'
pipeline {
    agent {
        kubernetes {
            label 'jenkins-kaniko-agent'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    command:
    - cat
    tty: true
  - name: git
    image: alpine/git
    command:
    - cat
    tty: true
"""
        }
    }

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = 'your-account-id.dkr.ecr.us-east-1.amazonaws.com/django-app-repo'
        IMAGE_TAG = "build-\${env.BUILD_ID}"
        GIT_REPO = 'git@github.com:your-user/helm-chart-repo.git'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'git@github.com:your-user/django-app.git'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                container('kaniko') {
                    sh '''
                    /kaniko/executor --dockerfile=Dockerfile --context=./ --destination=\$ECR_REPO:\$IMAGE_TAG --cleanup
                    '''
                }
            }
        }

        stage('Update Helm Chart Tag') {
            steps {
                container('git') {
                    sh """
                    git clone \$GIT_REPO helm-chart
                    cd helm-chart
                    sed -i "s|tag:.*|tag: \$IMAGE_TAG|g" values.yaml
                    git config user.email "jenkins@example.com"
                    git config user.name "jenkins"
                    git add values.yaml
                    git commit -m "Update image tag to \$IMAGE_TAG"
                    git push origin main
                    """
                }
            }
        }
    }
}
EOF

# README.md
cat > README.md << EOF
# CI/CD Django App Pipeline

## Запуск Terraform

\`\`\`bash
terraform init
terraform apply
\`\`\`

## Jenkins

- URL: \`terraform output jenkins_url\`
- Логін: admin
- Пароль: з \`terraform output\` або values.yaml

## Jenkins Pipeline

- Збирає Docker-образ, пушить в ECR
- Оновлює Helm chart у Git
- Запускає Argo CD для деплою

## Argo CD

- URL: \`terraform output argo_cd_url\`
- Логін: admin
- Пароль: з kubectl (отримати через \`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode\`)

## Видалення

\`\`\`bash
terraform destroy
\`\`\`
EOF

# modules/s3-backend/s3.tf
cat > modules/s3-backend/s3.tf << EOF
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  versioning {
    enabled = true
  }

  tags = {
    Name = "Terraform State Bucket"
  }
}
EOF

# modules/s3-backend/dynamodb.tf
cat > modules/s3-backend/dynamodb.tf << EOF
resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
  }
}
EOF

# modules/s3-backend/variables.tf
cat > modules/s3-backend/variables.tf << EOF
variable "bucket_name" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "region" {
  type = string
}
EOF

# modules/s3-backend/outputs.tf
cat > modules/s3-backend/outputs.tf << EOF
output "bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_lock.name
}
EOF

# modules/ecr/ecr.tf
cat > modules/ecr/ecr.tf << EOF
resource "aws_ecr_repository" "repo" {
  name = var.repository_name
  image_scanning_configuration {
    scan_on_push = true
  }
}
EOF

# modules/ecr/variables.tf
cat > modules/ecr/variables.tf << EOF
variable "repository_name" {
  type = string
}
EOF

# modules/ecr/outputs.tf
cat > modules/ecr/outputs.tf << EOF
output "repository_url" {
  value = aws_ecr_repository.repo.repository_url
}
EOF

# modules/jenkins/jenkins.tf
cat > modules/jenkins/jenkins.tf << EOF
provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_ca)
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "4.0.0"
  namespace  = "jenkins"
  create_namespace = true

  values = [
    file("\${path.module}/values.yaml")
  ]
}
EOF

# modules/jenkins/values.yaml
cat > modules/jenkins/values.yaml << EOF
controller:
  image: "jenkins/jenkins:lts"
  adminPassword: "adminpassword"

  servicePort: 8080
  serviceType: LoadBalancer

agent:
  enabled: true
  kubernetes:
    namespace: jenkins
    yaml: |
      apiVersion: v1
      kind: Pod
      spec:
        containers:
          - name: kaniko
            image: gcr.io/kaniko-project/executor:latest
            args:
              - "--cache=true"
EOF

# modules/jenkins/variables.tf
cat > modules/jenkins/variables.tf << EOF
variable "eks_cluster_endpoint" {
  type = string
}

variable "eks_cluster_ca" {
  type = string
}
EOF

# modules/jenkins/outputs.tf
cat > modules/jenkins/outputs.tf << EOF
output "jenkins_url" {
  value = helm_release.jenkins.status[0].load_balancer[0].ingress[0].hostname
}
EOF

# modules/argo_cd/argo_cd.tf
cat > modules/argo_cd/argo_cd.tf << EOF
provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_ca)
  }
}

resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.23.5"
  namespace  = "argocd"
  create_namespace = true

  values = [
    file("\${path.module}/values.yaml")
  ]
}
EOF

# modules/argo_cd/values.yaml
cat > modules/argo_cd/values.yaml << EOF
server:
  service:
    type: LoadBalancer

configs:
  repositories:
    - url: https://github.com/your-user/helm-chart-repo.git
EOF

# modules/argo_cd/variables.tf
cat > modules/argo_cd/variables.tf << EOF
variable "eks_cluster_endpoint" {
  type = string
}

variable "eks_cluster_ca" {
  type = string
}
EOF

# modules/argo_cd/outputs.tf
cat > modules/argo_cd/outputs.tf << EOF
output "argo_cd_url" {
  value = helm_release.argo_cd.status[0].load_balancer[0].hostname
}
EOF

# charts/django-app/Chart.yaml
cat > charts/django-app/Chart.yaml << EOF
apiVersion: v2
name: django-app
version: 0.1.0
appVersion: "3.2"
EOF

# charts/django-app/values.yaml
cat > charts/django-app/values.yaml << EOF
image:
  repository: "<ECR_REPO_URL>"
  tag: "latest"

replicaCount: 1

service:
  type: ClusterIP
  port: 8000

env:
  DJANGO_SETTINGS_MODULE: "myproject.settings"

resources: {}
EOF

# charts/django-app/templates/deployment.yaml
cat > charts/django-app/templates/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django-app
spec:
  replicas: \{\{ .Values.replicaCount \}\}
  selector:
    matchLabels:
      app: django-app
  template:
    metadata:
      labels:
        app: django-app
    spec:
      containers:
        - name: django-app
          image: "\{\{ .Values.image.repository \}\}:\{\{ .Values.image.tag \}\}"
          ports:
            - containerPort: 8000
          env:
            - name: DJANGO_SETTINGS_MODULE
              value: \{\{ .Values.env.DJANGO_SETTINGS_MODULE | quote \}\}
EOF

# charts/django-app/templates/service.yaml
cat > charts/django-app/templates/service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: django-app
spec:
  selector:
    app: django-app
  ports:
    - protocol: TCP
      port: \{\{ .Values.service.port \}\}
      targetPort: 8000
  type: \{\{ .Values.service.type \}\}
EOF

# charts/django-app/templates/configmap.yaml
cat > charts/django-app/templates/configmap.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: django-app-config
data:
  DJANGO_SETTINGS_MODULE: \{\{ .Values.env.DJANGO_SETTINGS_MODULE \}\}
EOF

# charts/django-app/templates/hpa.yaml
cat > charts/django-app/templates/hpa.yaml << EOF
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: django-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: django-app
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
EOF

echo "Структура та файли створені. Тепер можна працювати над проектом."
