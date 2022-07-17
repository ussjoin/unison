# UNISON Calibre-Web

Hosting Calibre libraries on UNISON.

## Networking

This docker compose system *only* exposes Calibre-web via Tailscale; it doesn't allow local access.

## Installation (Docker Compose)

1. Grab this folder.
2. `./make_folders.sh`.
3. `docker compose up`
4. Open the URL that the `tailscale-calibre` container drops in the output and authenticate it onto your Tailnet.
5. Modify `get_certs.sh` with your Tailnet's TLS domain.
6. In another terminal, `./get_certs.sh`.
7. Ctrl-C the `docker compose up` thing.
8. `docker compose up -d`. Now it'll stay up and come back if something falls over.

## Installation (Calibre-Web)

See the documentation at <https://github.com/janeczku/calibre-web>.

## Do on Tailscale Admin Page

Set up the ACL to allow access to the `calibre` node on port 443 (and optionally, port 80; it will redirect to 443). Note that if you allow direct access to port 8083, that will bypass Nginx, so that's your call, but I wouldn't.
