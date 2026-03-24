#!/bin/sh

docker compose \
  --project-directory $(pwd) \
  -f frappe_docker/compose.yaml \
  --env-file config.env \
  --env-file private.env \
  --env-file secrets.env \
  -f frappe_docker/overrides/compose.mariadb.yaml \
  -f frappe_docker/overrides/compose.redis.yaml \
  -f overrides.project_name.yaml \
  -f overrides.network.yaml \
  -f overrides.mariadb_version.yaml \
  -f overrides.archived_sites.yaml \
  -f overrides.caddy.yaml \
  -f overrides.tailscale.yaml \
  config \
  -o compose.yaml


