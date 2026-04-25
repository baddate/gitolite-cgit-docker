#!/usr/bin/env sh
set -euo pipefail

# ── SSH config ─────────────────────────────────────────────
if [ ! -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
fi

if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
fi

# ── Volume ownership ───────────────────────────────────────
stamp=/var/lib/git/.gitolite/.permissions-fixed
if [ "${FORCE_CHOWN:-}" = "1" ] || [ ! -f "$stamp" ]; then
    chown -R git:git /var/lib/git
    chmod 750 /var/lib/git
    mkdir -p "$(dirname "$stamp")"
    touch "$stamp" && chown git:git "$stamp"
else
    chown git:git /var/lib/git
    chmod 750 /var/lib/git
fi

# ── gitolite init ──────────────────────────────────────────
if [ ! -f /var/lib/git/.ssh/authorized_keys ]; then
    echo "$SSH_KEY" > "/tmp/${SSH_KEY_NAME}.pub"
    su git -c "gitolite setup -pk \"/tmp/${SSH_KEY_NAME}.pub\""
    rm "/tmp/${SSH_KEY_NAME}.pub"
fi

# ── gitolite config ───────────────────────────────────────
# FIX: idempotent — only copy default rc if one doesn't exist yet
# Previously this ran unconditionally, wiping user customisations on restart
if [ ! -f /var/lib/git/.gitolite.rc ]; then
    cp /usr/local/share/gitolite.rc.default /var/lib/git/.gitolite.rc
    chown git:git /var/lib/git/.gitolite.rc
    chmod 640 /var/lib/git/.gitolite.rc
fi

# ── SSH permissions ───────────────────────────────────────
if [ -d /var/lib/git/.ssh ]; then
    chown -R git:git /var/lib/git/.ssh
    chmod 700 /var/lib/git/.ssh
    [ -f /var/lib/git/.ssh/authorized_keys ] && chmod 600 /var/lib/git/.ssh/authorized_keys
fi

# ── START SSH ─────────────────────────────────────────────
exec /usr/sbin/sshd -D -e