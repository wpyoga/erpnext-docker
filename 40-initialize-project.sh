#!/bin/sh

. ./private.env

docker compose \
  -p ${PROJECT_NAME:-frappe-test-project} \
  -f compose.prebuilt.yaml \
  up \
  --build \
  --detach

echo
echo Check Tailscale logs: docker compose -p ${PROJECT_NAME:-frappe-test-project} logs tailscale

