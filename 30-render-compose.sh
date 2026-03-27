#!/bin/sh

set -eu

. ./project.env

if [ "${LISTEN_ON}" = "tailscale" ]; then
  EDGE_CONFIG="-f overrides.tailscale.yaml"
else
  EDGE_CONFIG="-f overrides.caddy_edge.yaml"
fi

docker compose \
  --project-directory $(pwd) \
  -f frappe_docker/compose.yaml \
  --env-file build.env \
  --env-file project.env \
  --env-file secrets.env \
  -f frappe_docker/overrides/compose.mariadb.yaml \
  -f frappe_docker/overrides/compose.redis.yaml \
  -f overrides.project_name.yaml \
  -f overrides.network.yaml \
  -f overrides.mariadb_version.yaml \
  -f overrides.archived_sites.yaml \
  -f overrides.caddy.yaml \
  ${EDGE_CONFIG} \
  config \
  -o compose.yaml

