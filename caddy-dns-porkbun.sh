#!/bin/sh

. ./secrets.env

cat <<EOF
{
	acme_dns porkbun {
		api_key ${DNS_API_KEY}
		api_secret_key ${DNS_API_SECRET}
	}
}
EOF
