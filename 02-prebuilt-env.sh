#!/bin/sh

ENV_FILE=prebuilt.env

. ./secrets.env
. ./private.env

PROJECT_NAME=${PROJECT_NAME:-frappe-test-project}

# https://github.com/frappe/frappe_docker/blob/main/docs/02-setup/04-env-variables.md

# this is the docker image tag, v15 means latest v15 build
# it is possible to specify a particular version, for example v15.96.1
ERPNEXT_IMAGE_VERSION=v15

# MariaDB root password
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-123}

# Email address for Let's Encrypt account
LETSENCRYPT_ACCOUNT_EMAIL=${LETSENCRYPT_ACCOUNT_EMAIL:-mail@example.com}


cat >frappe_docker/${ENV_FILE} <<EOF
PROJECT_NAME=${PROJECT_NAME}
ERPNEXT_VERSION=${ERPNEXT_IMAGE_VERSION}
DB_PASSWORD=${MARIADB_ROOT_PASSWORD}
LETSENCRYPT_EMAIL=${LETSENCRYPT_ACCOUNT_EMAIL}
EOF

