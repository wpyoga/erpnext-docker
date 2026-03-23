#!/bin/sh

cd frappe_docker

docker compose \
  -f compose.yaml \
  --env-file prebuilt.env \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f ../overrides.project_name.yaml \
  -f ../overrides.network.yaml \
  -f ../overrides.mariadb_version.yaml \
  -f ../overrides.archived_sites.yaml \
  -f ../overrides.tailscale.yaml \
  config \
  -o compose.prebuilt.yaml


