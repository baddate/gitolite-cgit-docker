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

# ── Volume ownership fix ───────────────────────────────────
# Skipped after first run (stamp file) unless FORCE_CHOWN=1.
# Checks UID:GID — GID must be 2000 (gitrepos) so fcgiwrap in the
# cgit container can read repositories via gitrepos group membership.
_stamp=/var/lib/git/.gitolite/.permissions-fixed
_owner="$(stat -c '%u:%g' /var/lib/git 2>/dev/null || echo 0:0)"
if [ "${FORCE_CHOWN:-}" = "1" ] || [ ! -f "$_stamp" ] || [ "$_owner" != "1000:2000" ]; then
    chown -R 1000:2000 /var/lib/git
    chmod 750 /var/lib/git
    # setgid on repositories dir: new subdirs inherit gitrepos (GID 2000) as
    # their group, so core.sharedRepository=group propagates correctly without
    # needing --shared on every git init.
    [ -d /var/lib/git/repositories ] && chmod g+s /var/lib/git/repositories
    # One-time migration: make existing repo objects group-readable.
    # core.sharedRepository=group only affects newly written files; existing
    # objects need a manual fix on first run.
    chmod -R g+rX /var/lib/git/repositories 2>/dev/null || true
    find /var/lib/git/repositories -type d -exec chmod g+s {} + 2>/dev/null || true
    mkdir -p "$(dirname "$_stamp")"
    touch "$_stamp"
    chown 1000:2000 "$_stamp"
fi

# ── gitolite init (run as git user) ────────────────────────
if [ ! -f /var/lib/git/.ssh/authorized_keys ]; then
    echo "$SSH_KEY" > "/tmp/${SSH_KEY_NAME}.pub"
    chmod 644 "/tmp/${SSH_KEY_NAME}.pub"
    su-exec git gitolite setup -pk "/tmp/${SSH_KEY_NAME}.pub"
    rm -f "/tmp/${SSH_KEY_NAME}.pub"
fi

# ── git global config ──────────────────────────────────────
# Idempotent — set on every restart so the config is present
# even if gitolite was initialised on a previous container run.
# core.sharedRepository=group: new objects get g+r with group=gitrepos (GID 2000).
# Written to /var/lib/git/.gitconfig (git HOME), read by git on every init.
su-exec git git config --global core.sharedRepository group

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
