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

RUN apk add --no-cache \
        git gitolite openssh perl tini && \
    id git >/dev/null 2>&1 || adduser -D -h /var/lib/git -s /bin/sh git && \
    mkdir -p /var/lib/git && \
    chown -R git:git /var/lib/git

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

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]