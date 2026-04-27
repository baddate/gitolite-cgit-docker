#!/usr/bin/env sh

set -euo pipefail

# ── Runtime directory setup ───────────────────────────────────────────────────
# All mkdir/chown/chmod in one place. Runs as root (container starts as root).
# Permissions rationale:
#   /run/fcgiwrap  — fcgiwrap Unix socket dir; nginx reads socket (g+rx via nginx group)
#   /run/nginx     — nginx pid/lock files; owned by nginx
#   /tmp/nginx     — nginx temp files; container has read-only rootfs, needs tmpfs
#   /run/cgit-cache — cgit page cache; fcgiwrap writes, nginx has no need to write
setup_runtime_dirs() {
    mkdir -p /run/fcgiwrap   && chown fcgiwrap:nginx  /run/fcgiwrap   && chmod 0750 /run/fcgiwrap
    mkdir -p /run/nginx      && chown nginx:nginx     /run/nginx      && chmod 0755 /run/nginx
    mkdir -p /tmp/nginx      && chown nginx:nginx     /tmp/nginx      && chmod 0700 /tmp/nginx
    mkdir -p /run/cgit-cache && chown fcgiwrap:nginx  /run/cgit-cache && chmod 0750 /run/cgit-cache
}
setup_runtime_dirs

# ── cgitrc ────────────────────────────────────────────────────────────────────
# Generated at runtime into /run (tmpfs) so the image stays read-only.
# Owned by fcgiwrap:nginx, mode 0640: fcgiwrap reads it, nginx has no need.
CONFIG=/run/cgitrc
mkdir -p "$(dirname "$CONFIG")"
cp /usr/local/share/cgitrc.template "$CONFIG"
chown fcgiwrap:nginx "$CONFIG"
chmod 0640 "$CONFIG"

# ── Dynamic Runtime Config Injection (with Comment Support) ──────────────────

echo "Initializing cgitrc with environment variables..."

env | grep '^GIT_' | while read -r line; do
    var_name=${line%%=*}
    eval var_value="\$$var_name"

    [ -z "$var_value" ] && continue

    # Transform: GIT_ROOT_TITLE -> root-title
    config_key=$(echo "${var_name#GIT_}" | tr '[:upper:]' '[:lower:]' | tr '_' '-')

    # Support both 'key=' and '#key='
    # 1. Check if the key exists (commented or not)
    if grep -iq "^#\?${config_key}=" "$CONFIG"; then
        # 2. Replace the line: remove leading # if present, and update value
        # Using a different delimiter (pipe |) in sed to avoid issues with URLs in values
        sed -i "s|^#\?${config_key}=.*|${config_key}=${var_value}|" "$CONFIG"
        printf "  [APPLIED] %-25s -> %s\n" "$var_name" "$config_key"
    else
        echo "  [IGNORE] $config_key not found in $CONFIG template."
    fi
done

echo "Configuration injection complete."

# ── Cache invalidation listener ───────────────────────────────────────────────
# Listens on TCP 9000 (internal network only, not exposed in docker-compose).
# gitolite's post-receive hook connects and sends a shared secret token;
# if it matches REPO_INVALIDATE_SECRET, the scanrc cache is wiped so newly
# created repositories appear in cgit without a restart.
#
# Security notes:
#   - Port 9000 is NOT exposed in docker-compose (no ports: mapping), so it
#     is only reachable from containers on the same Docker network.
#   - The secret prevents any container on git-net from triggering a flush;
#     deleting cache files is low-risk but the check costs nothing.
#   - socat forks per connection (fork) and exits after one command (EXEC).
#
if [ -n "${REPO_INVALIDATE_SECRET:-}" ]; then
    SECRET="$REPO_INVALIDATE_SECRET"

    socat TCP-LISTEN:9000,bind=0.0.0.0,fork,reuseaddr \
        EXEC:"/bin/sh -c '
            read token
            echo \"[cgit] received: \$token\" >&2

            if [ \"\$token\" = \"$SECRET\" ]; then
                find /run/cgit-cache -maxdepth 1 -name rc-* -delete
                echo \"[cgit] cache invalidated\" >&2
                echo OK
            else
                echo \"[cgit] invalid token\" >&2
                echo FAIL
            fi
        '" \
        2>&1 &

    echo "[cgit] cache invalidation listener started on :9000"
else
    echo "[cgit] REPO_INVALIDATE_SECRET not set, disabled" >&2
fi

# ── fcgiwrap ──────────────────────────────────────────────────────────────────
spawn-fcgi \
    -s /run/fcgiwrap/fcgiwrap.socket \
    -u fcgiwrap -g nginx -M 0660 \
    -f /usr/bin/fcgiwrap

# Wait for socket to be ready before starting nginx.
# Avoids 502 on the first few requests after container start.
_timeout=50
while [ ! -S /run/fcgiwrap/fcgiwrap.socket ]; do
    if [ "$_timeout" -le 0 ]; then
        echo "ERROR: fcgiwrap socket not ready after 5s" >&2
        exit 1
    fi
    sleep 0.1
    _timeout=$((_timeout - 1))
done

# ── nginx ─────────────────────────────────────────────────────────────────────
exec nginx -g "daemon off;"