#!/bin/sh

docker compose \
  -f frappe_docker/compose.yaml \
  --env-file prebuilt.env \
  -f frappe_docker/overrides/compose.mariadb.yaml \
  -f frappe_docker/overrides/compose.redis.yaml \
  -f overrides.project_name.yaml \
  -f overrides.network.yaml \
  -f overrides.mariadb_version.yaml \
  -f overrides.archived_sites.yaml \
  -f overrides.tailscale.yaml \
  config \
  -o compose.prebuilt.yaml


