FROM ghcr.io/ausaccessfed/aws-cli:1.1

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
