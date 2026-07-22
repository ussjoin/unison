#!/usr/bin/env bash

DAYS_TO_KEEP=90
NUMBER_OF_BACKUPS=3

NAME_OF_SERVICE=authentik
DATE_OF_BACKUP=$(date -I -u) # Uses UTC date

# This cute trick, to cd to the folder this script is located in, found at
# https://stackoverflow.com/a/3355423 .

cd "$(dirname "$0")"

# Bring service down
docker compose pull
docker compose down

# Take backup
# Authentik backup notes: https://docs.goauthentik.io/sys-mgmt/ops/backup-restore/
# Postgres backup notes: https://www.postgresql.org/docs/current/backup-file.html
echo "Authentik: beginning backup."

for VOLUME in authentik-data authentik-templates postgres-data
do
	BACKUPFILE=${NAME_OF_SERVICE}-$VOLUME-${DATE_OF_BACKUP}
	docker run --rm \
	-v ${NAME_OF_SERVICE}_${VOLUME}:/tmp/${BACKUPFILE} \
	-v ./backups:/tmp/backups \
	-w /tmp \
	alpine:latest \
	tar -czf /tmp/backups/${BACKUPFILE}.tgz ./${BACKUPFILE}
done

##### HA HA HA HA actually just do https://www.postgresql.org/docs/current/backup-file.html
##### and call it a day, don't muck with all this stuff since the db will always be shut down
##### because in this house, we know 5min of downtime is fine


# Trim number of files
NUMBER_OF_FILES_TO_KEEP=$((${DAYS_TO_KEEP}*${NUMBER_OF_BACKUPS}))
echo "Authentik: Backup complete. Trimming backups to ${DAYS_TO_KEEP} days, ${NUMBER_OF_FILES_TO_KEEP} total files."
ls -1 ./backups | sort -r | tail -n +${NUMBER_OF_FILES_TO_KEEP} | xargs rm > /dev/null 2>&1
echo "Authentik: Trim complete."

# Bring service up
docker compose up -d

