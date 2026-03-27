#!/bin/sh

set -eu

. ./project.env
. ./secrets.env

is_ipv4() {
  # with a trailing dot, the regex becomes a lot simpler
  echo "$1". | grep -qs -E '^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])[.]){1,4}$'
}

# Determine edge configuration

case "${LISTEN_ON}" in
  tailscale)
    TAILSCALE_IP=$(docker compose -p ${PROJECT_NAME} exec --interactive=false tailscale tailscale ip -4)
    if [ $? -eq 0 ] && is_ipv4 "${TAILSCALE_IP}"; then
      TAILSCALE=1
      LISTEN_IP="${TAILSCALE_IP}"
      echo "Using Tailscale sidecar IP address: ${LISTEN_IP}"
    else
      echo "Failed to retrieve Tailscale sidecar IP address: ${TAILSCALE_IP}"
      exit 1
    fi
    ;;
  eth0.me)
    IP_ADDR=$(mktemp)
    HTTP_STATUS=$(curl -sS -w "%{http_code}" https://eth0.me -o ${IP_ADDR})
    if [ $? -eq 0 ] && [ "${HTTP_STATUS}" = "200" ] && is_ipv4 "$(cat ${IP_ADDR})"; then
      TAILSCALE=
      LISTEN_IP="$(cat ${IP_ADDR})"
      echo "Using current server IP address: ${LISTEN_IP}"
    else
      echo "Failed to retrieve current server IP from eth0.me: ${HTTP_STATUS} $(cat ${IP_ADDR})"
      exit 1
    fi
    ;;
  *)
    if is_ipv4 "${LISTEN_ON}"; then
      TAILSCALE=
      LISTEN_IP="${LISTEN_ON}"
      echo "Using configured IP address: ${LISTEN_IP}"
    else
      echo "Unknown LISTEN_ON value: ${LISTEN_ON}"
      exit 1
    fi
    ;;
esac

# Process each site one by one

CADDY_IP=$(docker compose -p ${PROJECT_NAME} exec --interactive=false caddy hostname -i)
CADDYFILE=$(mktemp)

# Show warning about extra files in sites/
# There is a chance those files were accidentally missing the .env suffix

SITES_NON_ENV=$(ls sites/ | grep -v '\.env$')
if [ -n "${SITES_NON_ENV}" ]; then
  echo "Warning: ignoring files in sites/ without .env suffix:"
  echo "${SITES_NON_ENV}"
fi

ls ./sites/*.env | sort | while read SITE_ENV; do
  (
    . ${SITE_ENV}

    SUBDOMAIN=${SUBDOMAIN:-}

    if [ -n "${SUBDOMAIN}" ]; then
      SITE_NAME=${HOSTNAME}.${SUBDOMAIN}.${DOMAIN}
    else
      SITE_NAME=${HOSTNAME}.${DOMAIN}
    fi

    if [ "${WILDCARD}" = "1" ]; then
      if [ -n "${SUBDOMAIN}" ]; then
        DNS_RECORD="*.${SUBDOMAIN}.${DOMAIN}"
      else
        DNS_RECORD="*.${DOMAIN}"
      fi
    else
      DNS_RECORD=${SITE_NAME}
    fi

    # Check if the site is already active

    docker compose \
      -p ${PROJECT_NAME} \
      exec --interactive=false backend \
        test -e "sites/${SITE_NAME}/site_config.json" \
    && SITE_ACTIVE=1 \
    || SITE_ACTIVE=0

    # generate Caddyfile and then load it into caddy

    if [ ! -e caddy-https-${DNS_PROVIDER}.sh ]; then
      echo "DNS provider ${DNS_PROVIDER} not supported, skipping site ${SITE_NAME}"
      continue
    fi

    SITE_CADDYFILE=$(mktemp)
    sh caddy-https-"${DNS_PROVIDER}".sh "${SITE_ENV}" "${DNS_RECORD}" >> ${SITE_CADDYFILE}
    grep -qs -Fx "$(head -n 1 ${SITE_CADDYFILE})" "${CADDYFILE}" \
      || cat ${SITE_CADDYFILE} >> ${CADDYFILE}
    rm ${SITE_CADDYFILE}

    curl http://${CADDY_IP}:2019/load \
      -X POST \
      -H 'Content-Type: text/caddyfile' \
      --data-binary @${CADDYFILE}

    # If site is active, skip the following operations
    # We only needed to update the Caddy configuration
    if [ "${SITE_ACTIVE}" = 1 ]; then
      continue
    fi

    # Update DNS records

    if [ ! -e dns-update-${DNS_PROVIDER}.sh ]; then
      echo "DNS provider ${DNS_PROVIDER} not supported, skipping site ${SITE_NAME}"
      continue
    fi

    sh dns-update-${DNS_PROVIDER}.sh "${SITE_ENV}" "${DNS_RECORD}" "${LISTEN_IP}"

    # Create site

    echo "Creating site: ${SITE_NAME}"

    docker compose \
      -p ${PROJECT_NAME} \
      exec --interactive=false backend \
        bench new-site ${SITE_NAME} \
          --admin-password admin \
          --db-root-password ${DB_PASSWORD} \
          --mariadb-user-host-login-scope='172.%.%.%' \
          --install-app erpnext

    echo "Enabling scheduler..."

    docker compose \
      -p ${PROJECT_NAME} \
      exec --interactive=false backend \
        bench \
          --site ${SITE_NAME} \
          enable-scheduler
  )
done

# Cleanup

rm ${CADDYFILE}

