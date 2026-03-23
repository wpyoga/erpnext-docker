#!/bin/sh

ENV_FILE=prebuilt.env

# https://github.com/frappe/frappe_docker/blob/main/docs/environment-variables.md

# this is the docker image tag, v15 means latest v15 build
# it is possible to specify a particular version, for example v15.96.1
ERPNEXT_IMAGE_VERSION=v15

# MariaDB password
MARIADB_PASSWORD=123

# Email address for Let's Encrypt account
LETSENCRYPT_EMAIL=mail@example.com


cat >${ENV_FILE} <<EOF
ERPNEXT_VERSION=${ERPNEXT_IMAGE_VERSION}
DB_PASSWORD=${MARIADB_PASSWORD}
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
EOF

