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

# ── nginx config ─────────────────────────────────────────
# Only copy if not exists (idempotent)
if [ ! -f /etc/nginx/http.d/cgit.conf ]; then
  cp /usr/local/share/nginx-cgit.conf /etc/nginx/http.d/cgit.conf
fi


# ── runtime dirs ─────────────────────────────────────────
mkdir -p /run/fcgiwrap        && chown fcgiwrap:nginx /run/fcgiwrap && chmod 0750 /run/fcgiwrap
mkdir -p /run/nginx           && chown nginx:nginx    /run/nginx   && chmod 0755 /run/nginx
mkdir -p /var/log/nginx       && chown nginx:nginx    /var/log/nginx
mkdir -p /tmp/nginx           && chown nginx:nginx    /tmp/nginx

# ── fcgiwrap ─────────────────────────────────────────────
spawn-fcgi -s /run/fcgiwrap/fcgiwrap.socket \
    -u fcgiwrap -g nginx -M 0660 \
    -f /usr/bin/fcgiwrap &

# ── nginx ───────────────────────────────────────────────-
exec nginx -g "daemon off;"
