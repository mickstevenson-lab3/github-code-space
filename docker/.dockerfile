FROM ubuntu:22.04

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH=amd64
ARG AZP_AGENT_VERSION
ARG AZP_AGENT_DOWNLOAD_URL=https://download.agent.dev.azure.com
ARG AZP_AGENT_TARGETARCH=x64
ARG BUILDX_VERSION
ARG YQ_VERSION=v4.44.1
ARG KUBELOGIN_VERSION=v0.1.6
ARG KUBECTL_VERSION=v1.30.0
ARG HELM_VERSION=v3.16.3
ARG AZURE_CLI_VERSION=2.64.0-1~jammy
ARG CA_CERTIFICATES_VERSION=20240203~22.04.1
ARG CURL_VERSION=7.81.0-1ubuntu1.23
ARG GIT_VERSION=1:2.34.1-1ubuntu1.17
ARG UNZIP_VERSION=6.0-26ubuntu3.2
ARG GNUPG_VERSION=2.2.27-3ubuntu2.5
ARG APT_TRANSPORT_HTTPS_VERSION=2.4.14
ARG OPENSSH_CLIENT_VERSION=1:8.9p1-3ubuntu0.14
ARG SUDO_VERSION=1.9.9-1ubuntu2.6
ARG JQ_VERSION=1.6-2.1ubuntu3.1
ARG PYTHON3_VERSION=3.10.6-1~22.04.1
ARG PYTHON3_PIP_VERSION=22.0.2+dfsg-1ubuntu0.7
ARG PYTHON3_VENV_VERSION=3.10.6-1~22.04.1
ARG DOCKER_IO_VERSION=28.2.2-0ubuntu1~22.04.1

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates=${CA_CERTIFICATES_VERSION} \
    curl=${CURL_VERSION} \
    git=${GIT_VERSION} \
    unzip=${UNZIP_VERSION} \
    gnupg=${GNUPG_VERSION} \
    apt-transport-https=${APT_TRANSPORT_HTTPS_VERSION} \
    openssh-client=${OPENSSH_CLIENT_VERSION} \
    sudo=${SUDO_VERSION} \
    jq=${JQ_VERSION} \
    python3=${PYTHON3_VERSION} \
    python3-pip=${PYTHON3_PIP_VERSION} \
    python3-venv=${PYTHON3_VENV_VERSION} \
    docker.io=${DOCKER_IO_VERSION} \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH} \
    -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor \
      | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null && \
    echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ jammy main" \
      | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && apt-get install -y azure-cli=${AZURE_CLI_VERSION} && \
    rm -rf /var/lib/apt/lists/*

RUN curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl && \
    curl -L https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-${TARGETARCH}.zip \
      -o kubelogin.zip && \
    unzip kubelogin.zip -d /tmp/kubelogin && \
    mv /tmp/kubelogin/bin/linux_${TARGETARCH}/kubelogin /usr/local/bin/kubelogin && \
    chmod +x /usr/local/bin/kubelogin && \
    rm -rf kubelogin.zip /tmp/kubelogin && \
    curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz && \
    tar -zxvf helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz && \
    mv linux-${TARGETARCH}/helm /usr/local/bin/helm && \
    rm -rf linux-${TARGETARCH} helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz

RUN set -euo pipefail && \
    mkdir -p /usr/local/lib/docker/cli-plugins && \
    curl -L https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${TARGETARCH} \
      -o /usr/local/lib/docker/cli-plugins/docker-buildx && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

RUN mkdir -p /azp /opt/azp && \
    curl -fSL "${AZP_AGENT_DOWNLOAD_URL}/agent/${AZP_AGENT_VERSION}/vsts-agent-linux-${AZP_AGENT_TARGETARCH}-${AZP_AGENT_VERSION}.tar.gz" \
      | tar -xz -C /azp && \
    mv /azp/* /opt/azp && \
    rm -rf /azp && \
    useradd -m -s /bin/bash azp && \
    echo "azp ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/azp

USER azp
WORKDIR /home/azp

COPY ./start.sh ./
RUN chmod +x ./start.sh

RUN useradd -m -d /home/agent agent
RUN chown -R agent:agent /azp /home/agent

USER agent

ENV AZP_AGENT_NAME=ephemeral-agent \
    AZP_WORK=/opt/azp/work \
    AZP_HOME=/opt/azp \
    PATH="/home/azp/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT [ "./start.sh" ]