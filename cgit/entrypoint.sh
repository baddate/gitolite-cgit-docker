#!/usr/bin/env sh

set -euo pipefail

# ── runtime dirs ─────────────────────────────────────────
mkdir -p /run/fcgiwrap  && chown fcgiwrap:nginx /run/fcgiwrap && chmod 0750 /run/fcgiwrap
mkdir -p /run/nginx     && chown nginx:nginx    /run/nginx    && chmod 0755 /run/nginx
mkdir -p /tmp/nginx     && chown nginx:nginx    /tmp/nginx

# ── cgitrc ───────────────────────────────────────────────
CONFIG=/run/cgitrc
mkdir -p $(dirname $CONFIG) /run/cgit-cache && \
cp /usr/local/share/cgitrc.template "$CONFIG" && \
chown fcgiwrap:nginx "$CONFIG" && \
chown -R fcgiwrap:nginx /run/cgit-cache && \
chmod 0644 "$CONFIG" && chmod 0750 /run/cgit-cache

append_if_set() {
    key="$1"
    value="$2"

    [ -n "${value:-}" ] && printf '\n%s=%s\n' "$key" "$value" >> "$CONFIG"
}

append_bool() {
    key="$1"
    value="$2"

    case "${value:-}" in
        1|0|true|false|"") ;;
        *)
            echo "invalid boolean for $key: $value" >&2
            exit 1
            ;;
    esac

    [ -n "${value:-}" ] && printf '%s=%s\n' "$key" "$value" >> "$CONFIG"
}

append_if_set "clone-prefix" "$CGIT_CLONE_PREFIX"
append_if_set "root-title"   "$CGIT_ROOT_TITLE"
append_if_set "root-desc"    "$CGIT_DESC"
append_if_set "snapshots" "$CGIT_SNAPSHOT"

append_bool "enable-http-clone" "$ENABLE_HTTP_CLONE"



# ── fcgiwrap ─────────────────────────────────────────────
spawn-fcgi \
    -s /run/fcgiwrap/fcgiwrap.socket \
    -u fcgiwrap -g nginx -M 0660 \
    -f /usr/bin/fcgiwrap

# wait for socket to be ready before starting nginx
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