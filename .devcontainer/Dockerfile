FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && \
    apt-get install -y unzip curl awscli gnupg2 software-properties-common && \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor > hashicorp.gpg && \
    install -o root -g root -m 644 hashicorp.gpg /usr/share/keyrings && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform

RUN curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
