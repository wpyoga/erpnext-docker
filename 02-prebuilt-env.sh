#!/bin/sh

ENV_FILE=prebuilt.env

. ./secrets.env
. ./private.env

# https://github.com/frappe/frappe_docker/blob/main/docs/environment-variables.md

# this is the docker image tag, v15 means latest v15 build
# it is possible to specify a particular version, for example v15.96.1
ERPNEXT_IMAGE_VERSION=v15

# MariaDB root password
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-123}

# Email address for Let's Encrypt account
LETSENCRYPT_ACCOUNT_EMAIL=${LETSENCRYPT_ACCOUNT_EMAIL:-mail@example.com}


cat >frappe_docker/${ENV_FILE} <<EOF
ERPNEXT_VERSION=${ERPNEXT_IMAGE_VERSION}
DB_PASSWORD=${MARIADB_ROOT_PASSWORD}
LETSENCRYPT_EMAIL=${LETSENCRYPT_ACCOUNT_EMAIL}
EOF

