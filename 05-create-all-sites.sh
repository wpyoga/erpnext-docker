#!/bin/sh

. ./private.env

ACTIVE_SITES=$(mktemp)
ALL_SITES=$(mktemp)
NEW_SITES=$(mktemp)

docker compose \
  -p ${PROJECT_NAME:-frappe-test-project} \
  exec backend \
    find sites -name site_config.json \
  | cut -f 2 -d / \
  > ${ACTIVE_SITES}

sort sites.txt | uniq > ${ALL_SITES}
sort ${ACTIVE_SITES} ${ACTIVE_SITES} ${ALL_SITES} | uniq -u > ${NEW_SITES}

cat ${NEW_SITES} | xargs -n 1 sh 05a-create-single-site.sh

rm ${ACTIVE_SITES} ${ALL_SITES} ${NEW_SITES}

