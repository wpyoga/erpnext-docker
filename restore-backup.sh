#!/bin/sh

set -eu

BACKUP_TAR="$1"
OLD_SITE_NAME="$2"
NEW_SITE_NAME="$3"

OLD_SITE_NAME_UNDERSCORE=$(echo "${OLD_SITE_NAME}" | tr . _)
NEW_SITE_NAME_UNDERSCORE=$(echo "${NEW_SITE_NAME}" | tr . _)

. ./project.env
. ./secrets.env
. ./sites/"${NEW_SITE_NAME}".env

TEMP_DIR=$(mktemp -d)

# rename the files according to the site name

tar xf "${BACKUP_TAR}" -C ${TEMP_DIR}
cd ${TEMP_DIR}/sites
  mv -nT "${OLD_SITE_NAME}" "${NEW_SITE_NAME}"
  cd "${NEW_SITE_NAME}"/private/backups
    BACKUP_TIMESTAMP=$(ls *-"${OLD_SITE_NAME_UNDERSCORE}"-database.sql.gz | cut -f 1 -d -)

    tar xf "${BACKUP_TIMESTAMP}"-"${OLD_SITE_NAME_UNDERSCORE}"-files.tar
    tar xf "${BACKUP_TIMESTAMP}"-"${OLD_SITE_NAME_UNDERSCORE}"-private-files.tar
    rm "${BACKUP_TIMESTAMP}"-"${OLD_SITE_NAME_UNDERSCORE}"-files.tar
    rm "${BACKUP_TIMESTAMP}"-"${OLD_SITE_NAME_UNDERSCORE}"-private-files.tar

    mv -n "${BACKUP_TIMESTAMP}"-"${OLD_SITE_NAME_UNDERSCORE}"-site_config_backup.json "${BACKUP_TIMESTAMP}"-"${NEW_SITE_NAME_UNDERSCORE}"-site_config_backup.json
    mv -n "${BACKUP_TIMESTAMP}"-"${OLD_SITE_NAME_UNDERSCORE}"-database.sql.gz "${BACKUP_TIMESTAMP}"-"${NEW_SITE_NAME_UNDERSCORE}"-database.sql.gz

    mv -nT "${OLD_SITE_NAME}" "${NEW_SITE_NAME}"
    tar c "${NEW_SITE_NAME}"/public/files > "${BACKUP_TIMESTAMP}"-"${NEW_SITE_NAME_UNDERSCORE}"-files.tar
    tar c "${NEW_SITE_NAME}"/private/files > "${BACKUP_TIMESTAMP}"-"${NEW_SITE_NAME_UNDERSCORE}"-private-files.tar
    rm -r "${NEW_SITE_NAME}"
  cd ../../../..
  tar c sites/"${NEW_SITE_NAME}"/private/backups > backup-renamed.tar

docker compose \
  -p ${PROJECT_NAME} \
  exec --interactive=false backend \
    bench new-site ${NEW_SITE_NAME} \
      --admin-password admin \
      --db-root-password ${DB_PASSWORD} \
      --mariadb-user-host-login-scope='172.%.%.%'

echo "Putting site ${NEW_SITE_NAME} into maintenance mode"
docker compose \
  -p ${PROJECT_NAME} \
  exec --interactive=false backend \
    bench --site ${NEW_SITE_NAME} \
      set-maintenance-mode on

echo "Restoring site..."

cat backup-renamed.tar \
  | docker compose \
    -p ${PROJECT_NAME} \
    exec -T backend \
      tar xv

docker compose \
  -p ${PROJECT_NAME} \
  exec --interactive=false backend \
    bench --site ${NEW_SITE_NAME} \
      restore \
      --db-root-password ${DB_PASSWORD} \
      sites/"${NEW_SITE_NAME}"/private/backups/"${BACKUP_TIMESTAMP}"-"${NEW_SITE_NAME_UNDERSCORE}"-database.sql.gz

# with-private-files is buggy, so we have to extract the files ourselves

echo "Restoring files manually..."

docker compose \
  -p ${PROJECT_NAME} \
  exec --interactive=false backend \
    tar xvf sites/${NEW_SITE_NAME}/private/backups/"${BACKUP_TIMESTAMP}"-"${NEW_SITE_NAME_UNDERSCORE}"-files.tar -C sites

docker compose \
  -p ${PROJECT_NAME} \
  exec --interactive=false backend \
    tar xvf sites/${NEW_SITE_NAME}/private/backups/"${BACKUP_TIMESTAMP}"-"${NEW_SITE_NAME_UNDERSCORE}"-private-files.tar -C sites

# enable scheduler and enable site

echo "Running migrate..."
docker compose \
  -p ${PROJECT_NAME} \
  exec --interactive=false backend \
    bench --site ${NEW_SITE_NAME} \
      migrate

echo "Clearing cache..."
docker compose \
  -p ${PROJECT_NAME} \
  exec --interactive=false backend \
    bench --site ${NEW_SITE_NAME} \
      clear-cache

echo -n "Enabling scheduler... "
docker compose \
  -p ${PROJECT_NAME} \
  exec --interactive=false backend \
    bench --site ${NEW_SITE_NAME} \
      enable-scheduler

echo "Putting site ${NEW_SITE_NAME} out of maintenance mode"
docker compose \
  -p ${PROJECT_NAME} \
  exec --interactive=false backend \
    bench --site ${NEW_SITE_NAME} \
      set-maintenance-mode off

rm -r $TEMP_DIR

