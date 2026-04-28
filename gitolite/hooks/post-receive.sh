#!/bin/sh
# post-receive: notify cgit to invalidate its repository list cache.
#
# Sends REPO_INVALIDATE_SECRET to cgit's cache invalidation listener (TCP 9000).
# cgit deletes rc-* files and re-scans repositories on the next request,
# making newly created repositories visible immediately.

if [ -f /tmp/gitolite.env ]; then
    . /tmp/gitolite.env
else
    echo "post-receive: warning: /tmp/gitolite.env not found" >&2
fi

SOCAT_HOST="${SOCAT_HOST:-cgit}"
SOCAT_PORT="${SOCAT_PORT:-9000}"
SECRET="${REPO_INVALIDATE_SECRET:-}"

if [ -z "$SECRET" ]; then
    echo "post-receive: REPO_INVALIDATE_SECRET not set, skipping cache invalidation" >&2
    exit 0
fi

if ! printf '%s\n' "$SECRET" | nc -w2 "$SOCAT_HOST" "$SOCAT_HOST" 2>/dev/null; then
    # Non-fatal: cgit cache will expire on its own via cache-scanrc-ttl
    echo "post-receive: warning: could not reach cgit cache invalidation listener" >&2
fi

exit 0
