#!/bin/sh

set -eu

SITE_ENV="$1"
DNS_RECORD="$2"

. "${SITE_ENV}"

cat <<EOF
https://${DNS_RECORD} {
	reverse_proxy http://frontend:8080
	tls {
		dns porkbun {
			api_key ${DNS_API_KEY}
			api_secret_key ${DNS_API_SECRET}
		}
	}
}
EOF

