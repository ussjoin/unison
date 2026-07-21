#!/usr/bin/env bash

# This cute trick, to cd to the folder this script is located in, found at
# https://stackoverflow.com/a/3355423 .

cd "$(dirname "$0")"



docker compose pull

docker compose down

# Take backup

echo "archivewarrior does not require backing up."
echo "Backup complete."

docker compose up -d

