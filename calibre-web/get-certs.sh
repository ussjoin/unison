#!/bin/bash

SERVICE_NAME=calibre
DOMAIN=hippo-acoustic.ts.net


# These next two lines are a workaround for https://github.com/tailscale/tailscale/issues/5072; can remove with Tailscale 1.28 according to the note there
docker exec tailscaled-${SERVICE_NAME} mkdir -p /var/run/tailscale
docker exec tailscaled-${SERVICE_NAME} ln -s /tmp/tailscaled.sock /var/run/tailscale/tailscaled.sock 

docker exec tailscaled-${SERVICE_NAME} tailscale cert --cert-file /var/lib/tailscale/${SERVICE_NAME}.${DOMAIN}.crt --key-file /var/lib/tailscale/${SERVICE_NAME}.${DOMAIN}.key ${SERVICE_NAME}.${DOMAIN}
# Chown so that the running user can read the files, instead of root
docker exec tailscaled-${SERVICE_NAME} chown `id -u`:`id -g` /var/lib/tailscale/${SERVICE_NAME}.${DOMAIN}.key /var/lib/tailscale/${SERVICE_NAME}.${DOMAIN}.crt

mkdir -p ./nginxdata/certs/
mv ./tailscaledata/${SERVICE_NAME}.${DOMAIN}.* ./nginxdata/certs/

# nginx container uses uid/gid 101
sudo chown -R 101:101 ./nginxdata/certs

