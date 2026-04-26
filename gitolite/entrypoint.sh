#!/usr/bin/env sh
set -euo pipefail

# ── SSH host config (root needed: writes to /etc/ssh) ──────
if [ ! -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
fi

# Generate host key as root; owned by root, readable by sshd
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
fi

# ── Volume ownership fix (only on first run or forced) ─────
# Because the image pins git to UID/GID 1000 and Docker volumes inherit
# the ownership baked into the image at VOLUME declaration time, this
# chown should be a no-op on normal restarts.  It is kept here solely
# to recover from volumes created by older image versions with a
# different UID, and is skipped once the stamp file exists.
stamp=/var/lib/git/.gitolite/.permissions-fixed
if [ "${FORCE_CHOWN:-}" = "1" ] || [ ! -f "$stamp" ]; then
    chown -R 1000:1000 /var/lib/git
    chmod 750 /var/lib/git
    mkdir -p "$(dirname "$stamp")"
    touch "$stamp"
    chown 1000:1000 "$stamp"
fi

# ── gitolite init (run as git user) ────────────────────────
if [ ! -f /var/lib/git/.ssh/authorized_keys ]; then
    echo "$SSH_KEY" > "/tmp/${SSH_KEY_NAME}.pub"
    su-exec git gitolite setup -pk "/tmp/${SSH_KEY_NAME}.pub"
    rm "/tmp/${SSH_KEY_NAME}.pub"
fi

# ── gitolite config (run as git user) ──────────────────────
# Idempotent — only copy default rc if one doesn't exist yet,
# so user customisations are never overwritten on restart.
if [ ! -f /var/lib/git/.gitolite.rc ]; then
    su-exec git cp /usr/local/share/gitolite.rc.default /var/lib/git/.gitolite.rc
    chmod 640 /var/lib/git/.gitolite.rc
fi

# ── SSH dir permissions (run as root, files owned by git) ──
if [ -d /var/lib/git/.ssh ]; then
    chown -R 1000:1000 /var/lib/git/.ssh
    chmod 700 /var/lib/git/.ssh
    [ -f /var/lib/git/.ssh/authorized_keys ] && chmod 600 /var/lib/git/.ssh/authorized_keys
fi

# ── START sshd ─────────────────────────────────────────────
# sshd must start as root so it can:
#   1. bind port 22
#   2. manage its own privilege-separated child processes (ssh-privsep)
# It does NOT need to exec as git — it will drop privileges per-session
# via its internal privsep mechanism (AuthorizedKeysFile + ForceCommand).
#
# no-new-privileges:true is therefore intentionally NOT set on this
# container (see docker-compose.yml comment).  All git operations run
# as the git user via gitolite's ForceCommand, never as root.
exec /usr/sbin/sshd -D -e
