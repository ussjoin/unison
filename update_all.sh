#!/bin/bash
set -eux pipefail

for f in calibre-web forgejo grafana immich matrix pocorgtfo powerdata spis;
do
	cd /mnt/containers/$f
	docker compose pull && docker compose down && docker compose up -d
	cd ..
done

docker image prune -f

