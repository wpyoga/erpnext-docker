#!/bin/sh

# this should be run after the frappe project is up and running
# and this script should be used whenever we want to add another site (another tenant)

SITENAME=${1:-test.example.com}

. ./private.env
. ./secrets.env

docker compose \
  -p ${PROJECT_NAME:-frappe-test-project} \
  exec backend \
    bench new-site ${SITENAME} \
      --admin-password admin \
      --db-root-password ${MARIADB_ROOT_PASSWORD} \
      --mariadb-user-host-login-scope='172.%.%.%' \
      --install-app erpnext

