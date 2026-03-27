#!/bin/sh

set -eu

SITE_ENV="$1"
DNS_RECORD="$2"
LISTEN_IP="$3"

. "${SITE_ENV}"

if [ "${WILDCARD}" = "1" ]; then
  if [ -n "${SUBDOMAIN}" ]; then
    FQDN="*.${SUBDOMAIN}.${DOMAIN}"
  else
    FQDN="*.${DOMAIN}"
  fi
else
  if [ -n "${SUBDOMAIN}" ]; then
    FQDN="${HOSTNAME}.${SUBDOMAIN}.${DOMAIN}"
  else
    FQDN="${HOSTNAME}.${DOMAIN}"
  fi
fi

COMMAND_JSON=$(mktemp)

cat > ${COMMAND_JSON} <<EOF
{
  "puts": [
    {
      "name": "${FQDN}",
      "type": "A",
      "content": "${LISTEN_IP}",
      "ttl": 1
    }
  ]
}
EOF

echo "Creating DNS record: ${DNS_RECORD} A ${LISTEN_IP}"

curl "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/batch" \
  -X POST \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer ${DNS_API_TOKEN}" \
  --data-binary  @${COMMAND_JSON}
echo

rm ${COMMAND_JSON}

