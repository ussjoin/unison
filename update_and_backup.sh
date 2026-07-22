#!/usr/bin/env bash

echo "#####################################################"
echo "##  Beginning complete homelab update and backup.  ##"
echo "#####################################################"

set -euxo pipefail

declare -A applications=( \
	["authentik"]="authentik-data authentik-templates postgres-data" \
	["archivewarrior"]="" \
	["calibre-web"]="calibre-calibre-web-config" \
	["forgejo"]="" \
	["grafana"]="grafana-data" \
	["immich"]="" \
	["matrix"]="continuwuity-data" \
	["pocorgtfo"]="" \
	["powerdata"]="" \
	["spis"]="" \
	["tsidp"]="tsidp-data" \
	["uptime-kuma"]="" \
	["wavelog"]="wavelog-uploads wavelog-userdata" 
)

DAYS_TO_KEEP=90

for NAME_OF_SERVICE in "${!applications[@]}"
do
	echo "${NAME_OF_SERVICE}: beginning backup and update."
	DATE_OF_BACKUP=$(date -I -u) # Uses UTC date
	BACKUP_FOLDERS="${applications[$NAME_OF_SERVICE]}"
	NUMBER_OF_BACKUPS=$(echo $BACKUP_FOLDERS | wc -w)
	
	cd /mnt/containers/${NAME_OF_SERVICE}

	# These two specials need to run while the service is up.
	if [ "${NAME_OF_SERVICE}" = "wavelog" ]; then
		echo "${NAME_OF_SERVICE}: beginning special Wavelog backup process."
		docker compose up -d # Needs to be running to do the backup; this command succeeds if it's already running.
		set +x
		source .env
		# This next line is cheating.
		echo "+ docker compose exec wavelog-db mariadb-dump -u wavelog -pFAKE_PASS wavelog > wavelog_backup.sql"
		docker compose exec wavelog-db mariadb-dump -u wavelog -p$WAVELOG_PG_DB_PASS wavelog > wavelog_backup.sql
		set -x
		unset WAVELOG_PG_DB_PASS

		# Take the backup and move it to the appropriate folder.
		mkdir -p ./backups
		BACKUPFILE=${NAME_OF_SERVICE}-mariadb-backup-${DATE_OF_BACKUP}
		tar -czf ./backups/${BACKUPFILE}.tgz ./wavelog_backup.sql
		rm wavelog_backup.sql
		NUMBER_OF_BACKUPS=$((${NUMBER_OF_BACKUPS}+1))
		echo "${NAME_OF_SERVICE}: ending special Wavelog backup process."
	fi

	if [ "${NAME_OF_SERVICE}" = "forgejo" ]; then
		echo "${NAME_OF_SERVICE}: beginning special Forgejo backup process."
		docker compose up -d # Needs to be running to do the backup; this command succeeds if it's already running.

		# Create the backup in the appropriate folder.
		mkdir -p ./backups
		BACKUPFILE=${NAME_OF_SERVICE}-dump-${DATE_OF_BACKUP}
		docker compose exec -ti --user git forgejo forgejo dump --type tar.gz -f - > ./backups/${BACKUPFILE}.tgz

		NUMBER_OF_BACKUPS=$((${NUMBER_OF_BACKUPS}+1))
		echo "${NAME_OF_SERVICE}: ending special Forgejo backup process."
	fi


	# Bring service down
	docker compose pull

	echo "${NAME_OF_SERVICE}: terminating containers."
	docker compose down

	# This special needs to run while the service is down, as that's the only allowed way to do a Postgres
	# filesystem backup; otherwise it'll be inconsistent. See generally https://www.postgresql.org/docs/current/backup-file.html.
	# Why Immich *vocally* insists on using a bind mount for its postgres data isn't clear, but I get that
	# impression from the comments at https://github.com/immich-app/immich/blob/main/docker/example.env#L6-L7 .
	# Note that Immich photos are backed up completely separately.
	if [ "${NAME_OF_SERVICE}" = "immich" ]; then
		echo "${NAME_OF_SERVICE}: beginning special Immich backup process."

		# Create the backup in the appropriate folder.
		mkdir -p ./backups
		BACKUPFILE=${NAME_OF_SERVICE}-postgres-data-${DATE_OF_BACKUP}
		sudo tar -czf ./backups/${BACKUPFILE}.tgz ./postgres-data
		sudo chown $(whoami) ./backups/${BACKUPFILE}.tgz

		NUMBER_OF_BACKUPS=$((${NUMBER_OF_BACKUPS}+1))
		echo "${NAME_OF_SERVICE}: ending special Immich backup process."
	fi

	if [ "${NUMBER_OF_BACKUPS}" -gt "0" ]; then
	    # Take backup
		# Postgres backup notes: https://www.postgresql.org/docs/current/backup-file.html
		echo "${NAME_OF_SERVICE}: taking backup."

		mkdir -p ./backups

		for VOLUME in ${BACKUP_FOLDERS}
		do
			BACKUPFILE=${NAME_OF_SERVICE}-$VOLUME-${DATE_OF_BACKUP}
			docker run --rm \
			-v ${NAME_OF_SERVICE}_${VOLUME}:/tmp/${BACKUPFILE} \
			-v ./backups:/tmp/backups \
			-w /tmp \
			alpine:latest \
			tar -czf /tmp/backups/${BACKUPFILE}.tgz ./${BACKUPFILE}
		done

		# Trim number of files
		NUMBER_OF_FILES_TO_KEEP=$((${DAYS_TO_KEEP}*${NUMBER_OF_BACKUPS}))
		echo "${NAME_OF_SERVICE}: Backup taken. Trimming backups to ${DAYS_TO_KEEP} days, ${NUMBER_OF_FILES_TO_KEEP} total files."

		BACKUP_SYNC_FOLDER=/mnt/containers/complex-backup/${NAME_OF_SERVICE}
		mkdir -p ${BACKUP_SYNC_FOLDER}

		# Doing the trim on both sides avoids having to do an rsync for this degenerate case,
		# and it doesn't cause copying of extra data.
		# And rsync has gone LLM slop, sadly. So lt's do that.

		# Breaking up the bash one-liner to avoid having pipefail trigger when there are no files to remove.
		# tail -n needs a +1, see the man page.
		REMOVE_FILES=$(ls -1 ./backups | sort -r | tail -n +$((${NUMBER_OF_FILES_TO_KEEP} + 1)))
		REMOVE_FILES2=$(ls -1 ${BACKUP_SYNC_FOLDER} | sort -r | tail -n +$((${NUMBER_OF_FILES_TO_KEEP} - ${NUMBER_OF_BACKUPS} + 1)))
		if [ "$(echo $REMOVE_FILES | wc -w)" -gt "0" ]; then
			echo $REMOVE_FILES | xargs rm > /dev/null 2>&1
			echo $REMOVE_FILES2 | xargs rm > /dev/null 2>&1
		fi

		cp ./backups/* ${BACKUP_SYNC_FOLDER}

		echo "${NAME_OF_SERVICE}: Trim complete."
	fi

	# Bring service up
	docker compose up -d

	echo "${NAME_OF_SERVICE}: completing backup and update."
done

docker image prune -f

set +x

echo "######################################################"
echo "##    Ending complete homelab update and backup.    ##"
echo "##                 Share and enjoy.                 ##"
echo "######################################################"

