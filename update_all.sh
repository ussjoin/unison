#!/bin/bash
set -eux pipefail

for f in calibre-web gitlab pocorgtfo powerdata spis wavelog;
do
	cd /mnt/containers/$f
	docker compose pull && docker compose down && docker compose up -d
	cd ..
done

docker image prune -f

