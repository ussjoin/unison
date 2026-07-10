#!/bin/bash
set -ux

cd /mnt/containers/wavelog
docker compose pull

# Back up the Wavelog database.
source .env
docker exec wavelog-db mariadb-dump -u wavelog -p$WAVELOG_PG_DB_PASS wavelog > wavelog_backup.sql
head wavelog_backup.sql
unset WAVELOG_PG_DB_PASS

# Shut Wavelog down to back up non-db resources.
docker compose down

# Take the backup and move it to the appropriate folder.
THE_FILE=wavelog_backup_$(date +%F).tar.gz
tar -czf $THE_FILE wavelog-config wavelog_backup.sql wavelog-uploads wavelog-userdata
mv $THE_FILE /mnt/containers/complex-backup/wavelog/
rm wavelog_backup.sql

# Keep only the last 30 days of backups.
ls -1 /mnt/containers/complex-backup/wavelog/* | sort -r | tail -n +30 | xargs rm > /dev/null 2>&1

# Bring Wavelog back up and run the image prune.
docker compose up -d
docker image prune -f

