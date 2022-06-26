# Container image that runs your code
FROM alpine:3.10

RUN apk add --no-cache \
	jq \
        git \
        python3 \
        py3-pip \
    && pip3 install --upgrade pip \
    && pip3 install --no-cache-dir \
        awscli \
    && rm -rf /var/cache/apk/* \
    && git config --global user.email "ci@aaf.edu.au" \
    && git config --global user.name "AAF CI"

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
