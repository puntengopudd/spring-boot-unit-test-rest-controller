FROM jenkins/jenkins:lts

# Switch to root to install Docker, Terraform, and gcloud CLI
USER root

RUN apt-get update && \
    apt-get install -y curl wget unzip apt-transport-https ca-certificates gnupg lsb-release && \
    curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-28.2.2.tgz" | \
    tar -xzC /usr/local/bin --strip=1 docker/docker && \
    chmod +x /usr/local/bin/docker && \
    rm -rf /var/lib/apt/lists/*

# Install Terraform
ARG TERRAFORM_VERSION=1.12.2
RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    chmod +x /usr/local/bin/terraform && \
    rm terraform.zip

# Install Google Cloud CLI
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && \
    apt-get install -y google-cloud-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Optional: Install additional gcloud components (uncomment if needed)
# RUN gcloud components install kubectl gke-gcloud-auth-plugin --quiet

RUN usermod -aG root jenkins

# Switch back to jenkins user
USER jenkins

ENV DOCKER_BUILDKIT=1
ENV BUILDKIT_PROGRESS=plain
ENV DOCKER_CLI_EXPERIMENTAL=enabled

ARG BUILDX_URL=https://github.com/docker/buildx/releases/download/v0.25.0/buildx-v0.25.0.linux-amd64

RUN mkdir -p $HOME/.docker/cli-plugins && \
curl -fsSL ${BUILDX_URL} -o $HOME/.docker/cli-plugins/docker-buildx && \
chmod a+x $HOME/.docker/cli-plugins/docker-buildx

# Install essential plugins including Terraform
RUN jenkins-plugin-cli --plugins \
    workflow-aggregator \
    pipeline-stage-view \
    pipeline-build-step \
    pipeline-input-step \
    pipeline-milestone-step \
    pipeline-graph-analysis \
    docker-workflow \
    docker-commons \
    github \
    github-branch-source \
    git \
    dark-theme \
    blueocean \
    terraform