#!/bin/bash

mkdir -p lesson-7/modules/{s3-backend,vpc,ecr,eks}
mkdir -p lesson-7/charts/django-app/templates
cd lesson-7

# ==== Terraform ====

# backend.tf
cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket         = "your-s3-bucket-name"
    key            = "lesson-7/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "your-lock-table"
  }
}
EOF

# main.tf
cat > main.tf <<EOF
module "vpc" {
  source = "./modules/vpc"
}

module "eks" {
  source     = "./modules/eks"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
}

module "ecr" {
  source = "./modules/ecr"
}
EOF

# outputs.tf
cat > outputs.tf <<EOF
output "ecr_url" {
  value = module.ecr.repository_url
}

output "cluster_name" {
  value = module.eks.cluster_name
}
EOF

# ==== Dockerfile ====
cat > Dockerfile <<EOF
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /app

COPY requirements.txt ./
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . .

CMD ["gunicorn", "your_project_name.wsgi:application", "--bind", "0.0.0.0:8000"]
EOF

# ==== requirements.txt ====
cat > requirements.txt <<EOF
Django>=4.2
gunicorn
psycopg2-binary
EOF

# ==== Helm Chart Files ====
cat > charts/django-app/Chart.yaml <<EOF
apiVersion: v2
name: django-app
version: 0.1.0
EOF

cat > charts/django-app/values.yaml <<EOF
image:
  repository: <ECR-URL>
  tag: latest
  pullPolicy: Always

service:
  type: LoadBalancer
  port: 80

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 70

env:
  DJANGO_SECRET_KEY: "replace-me"
  DJANGO_DEBUG: "False"
  DB_HOST: "your-db-host"
  DB_PORT: "5432"
EOF

cat > charts/django-app/templates/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: django-app
  template:
    metadata:
      labels:
        app: django-app
    spec:
      containers:
        - name: django
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 8000
          envFrom:
            - configMapRef:
                name: django-config
EOF

cat > charts/django-app/templates/service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: django-service
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 8000
  selector:
    app: django-app
EOF

cat > charts/django-app/templates/configmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: django-config
data:
{{- range \$key, \$val := .Values.env }}
  {{ \$key }}: "{{ \$val }}"
{{- end }}
EOF

cat > charts/django-app/templates/hpa.yaml <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: django-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: django-app
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
EOF

echo "✅ Усі файли створено у каталозі lesson-7"
