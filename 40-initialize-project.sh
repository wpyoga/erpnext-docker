#!/bin/sh

set -eu

. ./project.env

docker compose \
  -p ${PROJECT_NAME} \
  -f compose.yaml \
  up \
  --build \
  --detach

echo
echo "Check Tailscale logs: docker compose -p ${PROJECT_NAME} logs -n 100 tailscale"
echo "Make sure the node is registered on the desired Tailnet"

