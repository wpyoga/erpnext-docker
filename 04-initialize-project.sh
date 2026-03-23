#!/bin/sh

cd frappe_docker
. ./prebuilt.env

docker compose \
  -p ${PROJECT_NAME:-frappe-test-project} \
  -f compose.prebuilt.yaml \
  up -d


