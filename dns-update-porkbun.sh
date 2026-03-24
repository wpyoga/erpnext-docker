#!/bin/sh

. ./private.env
. ./secrets.env

TAILSCALE_IP=$(docker compose -p ${PROJECT_NAME:-frappe-test-project} exec tailscale tailscale ip -4)

COMMAND_JSON=$(mktemp)

cat > ${COMMAND_JSON} <<EOF
{
  "name": "*.${SUBDOMAIN}",
  "type": "A",
  "content": "${TAILSCALE_IP}",
  "apikey": "${DNS_API_KEY}",
  "secretapikey": "${DNS_API_SECRET}"
}
EOF

echo Removing any existing records for *.${SUBDOMAIN}.${DOMAIN} ...

curl "https://api.porkbun.com/api/json/v3/dns/deleteByNameType/${DOMAIN}/A/*.${SUBDOMAIN}" \
  -X POST \
  -H 'Content-Type: application/json' \
  --data-binary  @${COMMAND_JSON}
echo

echo Creating a single record: *.${SUBDOMAIN}.${DOMAIN} A ${TAILSCALE_IP}

curl "https://api.porkbun.com/api/json/v3/dns/create/${DOMAIN}" \
  -X POST \
  -H 'Content-Type: application/json' \
  --data-binary  @${COMMAND_JSON}
echo

rm ${COMMAND_JSON}

