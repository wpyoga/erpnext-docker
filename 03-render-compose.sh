#!/bin/sh

cd frappe_docker

docker compose \
  -f compose.yaml \
  --env-file prebuilt.env \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  config \
  -o compose.prebuilt.yaml


