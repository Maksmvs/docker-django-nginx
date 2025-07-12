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
