# syntax=docker/dockerfile:1.7
FROM alpine:3.23

SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

# FIX: merge apk + user setup into one RUN — reduces layers
# FIX: removed redundant `id git` check (git user never exists in alpine base)
# FIX: added `-s /bin/sh` — gitolite hooks require a real shell
# FIX: removed /var/run/sshd mkdir — unused (sshd uses /run/sshd on Alpine)
RUN apk add --no-cache \
        git \
        gitolite \
        openssh \
        perl \
        tini && \
    adduser -D -h /var/lib/git -s /bin/sh git && \
    chown -R git:git /var/lib/git

COPY sshd_config            /etc/ssh/sshd_config.default
COPY gitolite.rc            /usr/local/share/gitolite.rc.default

COPY entrypoint.sh          /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/var/lib/git", "/etc/ssh"]

EXPOSE 22

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]