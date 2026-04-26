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

# Pin git to a fixed UID/GID (1000:1000) so the Docker volume inherits the
# correct ownership without needing a runtime chown.
# su-exec replaces gosu and is tiny / statically linked on Alpine.
RUN apk add --no-cache \
        git gitolite openssh perl tini su-exec && \
    addgroup -g 1000 git && \
    adduser  -D -u 1000 -G git -h /var/lib/git -s /bin/sh git && \
    mkdir -p /var/lib/git /etc/ssh && \
    chown -R 1000:1000 /var/lib/git && \
    chmod 750 /var/lib/git

COPY sshd_config            /etc/ssh/sshd_config.default
COPY gitolite.rc            /usr/local/share/gitolite.rc.default

# Trigger scripts referenced in gitolite.rc POST_GIT / POST_CREATE.
# Placed under LOCAL_CODE so gitolite can discover them without requiring
# a live gitolite-admin push.  The LOCAL_CODE path is set further below.
COPY auto-default-branch.sh /usr/local/share/gitolite-local/triggers/auto-default-branch
COPY set-master-branch.sh   /usr/local/share/gitolite-local/triggers/set-master-branch
RUN chmod +x \
        /usr/local/share/gitolite-local/triggers/auto-default-branch \
        /usr/local/share/gitolite-local/triggers/set-master-branch

COPY entrypoint.sh          /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/var/lib/git", "/etc/ssh"]

EXPOSE 22

# tini runs as root (needed to start sshd on port 22), but entrypoint drops
# to git for all gitolite operations and the sshd process model handles its
# own privilege separation internally.
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
