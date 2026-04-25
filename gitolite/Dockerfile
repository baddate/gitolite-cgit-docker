FROM alpine:3.23

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache \
    git \
    gitolite \
    openssh \
    perl \
    tini

# runtime dirs
RUN mkdir -p /var/lib/git /var/run/sshd && \
    if ! id git >/dev/null 2>&1; then \
        adduser -D -h /var/lib/git git; \
    fi && \
    chown -R git:git /var/lib/git

# ssh default config
COPY sshd_config /etc/ssh/sshd_config.default
COPY gitolite.rc /usr/local/share/gitolite.rc.default

# entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/var/lib/git", "/etc/ssh"]

EXPOSE 22

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
