FROM postgres:14-alpine

ARG VAULT_VERSION=1.13.0

RUN wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
    unzip vault_${VAULT_VERSION}_linux_amd64.zip && \
    cp vault /bin/vault

COPY vault-createdb.sh /docker-entrypoint-initdb.d/