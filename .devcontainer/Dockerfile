FROM mcr.microsoft.com/devcontainers/base:ubuntu

# 🔧 Базові пакети + AWS CLI v2
RUN apt-get update && \
    apt-get install -y unzip curl gnupg2 software-properties-common less && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# 🧱 Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor > hashicorp.gpg && \
    install -o root -g root -m 644 hashicorp.gpg /usr/share/keyrings && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y terraform

# 🛠 Helm
RUN curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
