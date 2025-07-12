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
