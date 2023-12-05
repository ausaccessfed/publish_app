# Container image that runs your code
FROM rockylinux:9 as base
USER root

ENV APP_DIR=/app

RUN groupadd -g 10001 app \
    && useradd -u 10001 -g 10001 --home ${APP_DIR} -ms /bin/bash app \
    && chmod g+s ${APP_DIR} \
    && mkdir -p ${APP_DIR}


WORKDIR ${APP_DIR}

COPY .FORCE_NEW_DOCKER_BUILD  .FORCE_NEW_DOCKER_BUILD

RUN yum update -y \
    && yum install -y \
    # renovate: datasource=yum repo=rocky-9-appstream-x86_64
    jq-1.6-15.el9 \
    # renovate: datasource=yum repo=rocky-9-appstream-x86_64
    git-2.39.3-1.el9_2 \
    && yum -y clean all \
    && rm -rf /var/cache/yum

USER app

RUN  git config --global user.email "ci@aaf.edu.au" \
    && git config --global user.name "AAF CI"


FROM base as aws-dependencies
USER root

RUN yum install -y \
    # renovate: datasource=yum repo=rocky-9-baseos-x86_64
    unzip-6.0-56.el9 \
    && yum -y clean all \
    && rm -rf "/var/cache/yum"

RUN arch="$(rpm --eval '%{_arch}')" && export arch \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "awscliv2.zip" \
    && unzip -q "awscliv2.zip" \
    && ./aws/install \
    && rm -rf "awscliv2.zip" "aws"

USER app

FROM base as kustomize
USER root

#  TODO: this one's release is kustomize/v5.2.1 do we need magic stuff?
# https://github.com/kubernetes-sigs/kustomize/releases
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
ARG KUSTOMIZE_VERSION=5.0.1

# Install Kustomize
RUN mkdir "/tmp/kustomize" \
    && curl -L -o "/tmp/kustomize/kustomize.tar.gz" \
    "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
    && tar -xzf "/tmp/kustomize/kustomize.tar.gz" -C "/tmp/kustomize" \
    && mv "/tmp/kustomize/kustomize" "/usr/local/bin" \
    && chmod +x "/usr/local/bin/kustomize" \
    && rm -rf "/tmp/kustomize"

USER app

FROM base as development
USER root

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

## Copy aws deps
COPY --chown=app --from=aws-dependencies /usr/local/aws-cli/v2/current/dist /usr/local/bin
COPY --chown=app --from=kustomize /usr/local/bin/kustomize /usr/local/bin


# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

USER app

FROM development as production
USER root

# Fix for https://github.com/goodwithtech/dockle/blob/master/CHECKPOINT.md#cis-di-0008
RUN find / -path /proc -prune -o -perm /u=s,g=s -type f -print -exec rm {} \;

USER app
