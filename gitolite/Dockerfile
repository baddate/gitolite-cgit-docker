# syntax=docker/dockerfile:1.7
FROM alpine:3.23

ARG BUILD_DATE
ARG REVISION
ARG VERSION=latest

LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.revision=${REVISION}
LABEL org.opencontainers.image.version=${VERSION}
LABEL org.opencontainers.image.title="gitolite"
LABEL org.opencontainers.image.description="Docker image with gitolite on Alpine"
LABEL org.opencontainers.image.url="https://github.com/baddate/gitolite-cgit-docker"
LABEL org.opencontainers.image.source="https://github.com/baddate/gitolite-cgit-docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"

SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

# ── Users and groups ─────────────────────────────────────────────────────────
# git(UID 1000, GID 1000): runs gitolite and sshd git sessions.
# gitrepos(GID 2000): shared group for read access to repositories.
#   - git is a member so new repo files inherit GID 2000
#     (via setgid on repositories dir + core.sharedRepository=group)
#   - cgit container's fcgiwrap joins this same GID to read repos
#   - GID 2000 must match exactly in both containers (enforced by -g 2000)
#
# gitolite's apk post-install script pre-creates the git user/group with a
# random ID, so delete in order (user first, then group) and recreate.
# passwd -u unlocks the account — adduser -D sets the password to '!' which
# causes sshd's account check to reject public-key logins with
# "User git not allowed because account is locked".
RUN apk add --no-cache \
        git gitolite openssh perl tini su-exec && \
    deluser  git 2>/dev/null || true && \
    delgroup git 2>/dev/null || true && \
    addgroup -g 2000 gitrepos && \
    addgroup -g 1000 git && \
    adduser  -D -u 1000 -G git -h /var/lib/git git && \
    addgroup git gitrepos && \
    passwd   -u git && \
    mkdir -p /var/lib/git /etc/ssh && \
    chown -R 1000:2000 /var/lib/git && \
    chmod 750 /var/lib/git

COPY sshd_config            /etc/ssh/sshd_config.default
COPY gitolite.rc            /usr/local/share/gitolite.rc.default

COPY triggers/auto-default-branch.sh /usr/local/share/gitolite-local/triggers/auto-default-branch
COPY triggers/set-master-branch.sh   /usr/local/share/gitolite-local/triggers/set-master-branch
COPY hooks/post-receive.sh        /usr/local/share/gitolite-local/hooks/common/post-receive

RUN chmod +x \
        /usr/local/share/gitolite-local/triggers/auto-default-branch \
        /usr/local/share/gitolite-local/triggers/set-master-branch \
        /usr/local/share/gitolite-local/hooks/common/post-receive && \
    chown -R 1000:2000 /usr/local/share/gitolite-local

COPY entrypoint.sh          /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/var/lib/git", "/etc/ssh"]

EXPOSE 22

# sshd has no built-in probe; verify the daemon process is alive.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD pgrep -x sshd >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]