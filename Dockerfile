# Container image that runs your code
FROM alpine:3.15

RUN apk add --no-cache \
    bash \
    jq \
    git \
    curl \
    python3 \
    py3-pip \
    && pip3 install --upgrade pip \
    && pip3 install --no-cache-dir \
    awscli \
    && rm -rf /var/cache/apk/* \
    && git config --global user.email "ci@aaf.edu.au" \
    && git config --global user.name "AAF CI"

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash \
    && mv /kustomize /usr/bin/kustomize
# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
