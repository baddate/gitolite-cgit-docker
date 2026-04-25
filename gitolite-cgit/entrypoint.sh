#!/usr/bin/env sh
set -euo pipefail

# ── SSH config ────────────────────────────────────────────────────────────────
if [ ! -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config.default /etc/ssh/sshd_config
fi
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
fi

# ── Volume ownership ──────────────────────────────────────────────────────────
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

# ── gitolite first-run ────────────────────────────────────────────────────────
if [ ! -f /var/lib/git/.ssh/authorized_keys ]; then
    echo "$SSH_KEY" > "/tmp/${SSH_KEY_NAME}.pub"
    su git -c "gitolite setup -pk \"/tmp/${SSH_KEY_NAME}.pub\""
    rm "/tmp/${SSH_KEY_NAME}.pub"
fi

# ── .gitolite.rc ─────────────────────────────────────────
cp /usr/local/share/gitolite.rc.default /var/lib/git/.gitolite.rc
chown git:git /var/lib/git/.gitolite.rc
chmod 640     /var/lib/git/.gitolite.rc

# ── cgitrc ────────────────────────────────────────────────────
if [ ! -f /var/lib/git/cgitrc ]; then
    envsubst < /usr/local/share/cgitrc.template > /var/lib/git/cgitrc
    [ -n "${CGIT_CLONE_PREFIX:-}" ] && printf 'clone-prefix=%s\n' "$CGIT_CLONE_PREFIX" >> /var/lib/git/cgitrc
    [ -n "${CGIT_ROOT_TITLE:-}"   ] && printf 'root-title=%s\n'   "$CGIT_ROOT_TITLE"   >> /var/lib/git/cgitrc
    [ -n "${CGIT_DESC:-}"         ] && printf 'root-desc=%s\n'    "$CGIT_DESC"         >> /var/lib/git/cgitrc
fi

# ── .ssh permissions ─────────────────────────────────────────────────────────
if [ -d /var/lib/git/.ssh ]; then
    chown -R git:git /var/lib/git/.ssh
    chmod 700 /var/lib/git/.ssh
    [ -f /var/lib/git/.ssh/authorized_keys ] && chmod 600 /var/lib/git/.ssh/authorized_keys
fi

# ── nginx(tmpfs, rebuild everytime)──────────────────────────────────────────────────
cp /usr/local/share/nginx-cgit.conf /etc/nginx/http.d/cgit.conf

# ── Runtime dirs ──────────────────────────────────────────────────────────────
mkdir -p /run/fcgiwrap        && chown fcgiwrap:nginx /run/fcgiwrap      && chmod 0750 /run/fcgiwrap
mkdir -p /run/nginx           && chown nginx:nginx    /run/nginx         && chmod 0755 /run/nginx
mkdir -p /var/log/nginx       && chown nginx:nginx    /var/log/nginx     && chmod 0755 /var/log/nginx
mkdir -p /var/lib/nginx/logs  && chown -R nginx:nginx /var/lib/nginx     && chmod -R 0755 /var/lib/nginx
mkdir -p /tmp/nginx           && chown nginx:nginx    /tmp/nginx         && chmod 0755 /tmp/nginx

ls -la /var/lib/nginx/
# ── Services ──────────────────────────────────────────────────────────────────
/usr/sbin/sshd -e

spawn-fcgi -s /run/fcgiwrap/fcgiwrap.socket \
    -u fcgiwrap -g git -U fcgiwrap -G nginx -M 0660 \
    -f /usr/bin/fcgiwrap &

umask 0027
git daemon --detach --syslog --reuseaddr \
    --base-path=/var/lib/git/repositories \
    --listen=0.0.0.0 --user=git --group=git \
    --enable=upload-pack \
    --disable=receive-pack \
    --disable=upload-archive \
    --informative-errors --verbose

exec su-exec nginx nginx -g "daemon off;"