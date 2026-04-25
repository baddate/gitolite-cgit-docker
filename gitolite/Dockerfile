# syntax=docker/dockerfile:1.7
FROM alpine:3.23

SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

RUN apk add --no-cache \
        git gitolite openssh perl tini && \
    id git >/dev/null 2>&1 || adduser -D -h /var/lib/git -s /bin/sh git && \
    mkdir -p /var/lib/git && \
    chown -R git:git /var/lib/git && \
    mkdir -p /var/lib/git

COPY sshd_config            /etc/ssh/sshd_config.default
COPY gitolite.rc            /usr/local/share/gitolite.rc.default

COPY entrypoint.sh          /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/var/lib/git", "/etc/ssh"]

EXPOSE 22

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]