FROM ubuntu:18.04

RUN (\
    set -eux \
    && apt-get update \
    && apt-get install -y \
        openssl \
)

RUN mkdir -p \
    /etc/pki.local \
    /opt/pki.local

WORKDIR /opt/pki.local