#!/bin/sh

set -eu

SITE_ENV="$1"
DNS_RECORD="$2"

. "${SITE_ENV}"

cat <<EOF
https://${DNS_RECORD} {
	reverse_proxy http://frontend:8080
	tls {
		dns cloudflare ${DNS_API_TOKEN}
	}
}
EOF

