#!/bin/sh

. ./private.env

ACTIVE_SITES=$(mktemp)
ALL_SITES=$(mktemp)
NEW_SITES=$(mktemp)
CADDYFILE=$(mktemp)

# generate Caddyfile and then load it into caddy

sh caddy-dns-"${DNS_PROVIDER}".sh > ${CADDYFILE}
for SITE in $(cat sites.txt); do
  printf "https://${SITE} {\n\treverse_proxy http://frontend:8080\n}\n" >> ${CADDYFILE}
done

CADDY_IP=$(docker compose -p ${PROJECT_NAME:-frappe-test-project} exec caddy hostname -i)

curl http://${CADDY_IP}:2019/load \
  -X POST \
  -H 'Content-Type: text/caddyfile' \
  --data-binary @${CADDYFILE}

# create the sites that need to be created

docker compose \
  -p ${PROJECT_NAME:-frappe-test-project} \
  exec backend \
    find sites -name site_config.json \
  | cut -f 2 -d / \
  > ${ACTIVE_SITES}

sort sites.txt | uniq > ${ALL_SITES}
sort ${ACTIVE_SITES} ${ACTIVE_SITES} ${ALL_SITES} | uniq -u > ${NEW_SITES}

for SITE in $(cat ${NEW_SITES}); do sh create-single-site.sh "$SITE"; done

# cleanup

rm ${ACTIVE_SITES} ${ALL_SITES} ${NEW_SITES} ${CADDYFILE}

