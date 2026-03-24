#!/bin/sh

. ./prebuilt.env

docker compose \
  -p ${PROJECT_NAME:-frappe-test-project} \
  -f compose.prebuilt.yaml \
  up -d

echo
echo Check Tailscale logs: docker compose -p ${PROJECT_NAME:-frappe-test-project} logs tailscale

