#!/usr/bin/env sh
set -euo pipefail

# ── cgitrc ───────────────────────────────────────────────
if [ ! -f /var/lib/git/cgitrc ]; then
    envsubst < /usr/local/share/cgitrc.template > /var/lib/git/cgitrc

    [ -n "${CGIT_CLONE_PREFIX:-}" ] && \
        printf 'clone-prefix=%s\n' "$CGIT_CLONE_PREFIX" >> /var/lib/git/cgitrc

    [ -n "${CGIT_ROOT_TITLE:-}" ] && \
        printf 'root-title=%s\n' "$CGIT_ROOT_TITLE" >> /var/lib/git/cgitrc

    [ -n "${CGIT_DESC:-}" ] && \
        printf 'root-desc=%s\n' "$CGIT_DESC" >> /var/lib/git/cgitrc
fi

# ── runtime dirs ─────────────────────────────────────────
mkdir -p /run/fcgiwrap  && chown fcgiwrap:nginx /run/fcgiwrap && chmod 0750 /run/fcgiwrap
mkdir -p /run/nginx     && chown nginx:nginx    /run/nginx    && chmod 0755 /run/nginx
mkdir -p /tmp/nginx     && chown nginx:nginx    /tmp/nginx

# ── fcgiwrap ─────────────────────────────────────────────
spawn-fcgi \
    -s /run/fcgiwrap/fcgiwrap.socket \
    -u fcgiwrap -g nginx -M 0660 \
    -f /usr/bin/fcgiwrap

# FIX: wait for socket to be ready before starting nginx
# avoids 502 on the first few requests after container start
_timeout=50
while [ ! -S /run/fcgiwrap/fcgiwrap.socket ]; do
    if [ "$_timeout" -le 0 ]; then
        echo "ERROR: fcgiwrap socket not ready after 5s" >&2
        exit 1
    fi
    sleep 0.1
    _timeout=$((_timeout - 1))
done

# ── nginx ─────────────────────────────────────────────────
exec nginx -g "daemon off;"