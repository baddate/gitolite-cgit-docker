# -----------------------------------------------------------------------------
# Stage 1: Build cgit from source
# -----------------------------------------------------------------------------
FROM alpine:3.22 AS cgit_builder
LABEL stage=cgit_builder

# Install build tools and development libraries
RUN apk add --no-cache \
    build-base git openssl-dev zlib-dev lua5.3-dev asciidoc pkgconfig gettext-dev

WORKDIR /usr/src
RUN git clone https://github.com/zx2c4/cgit
WORKDIR /usr/src/cgit

# If submodules are used (README mentions) — though usually not strictly required for basic build
RUN git submodule init && git submodule update

# Configure build options using variables referenced in README
# RUN echo "NO_LUA = 1" > config.mk && \
#     echo "NO_TCL = 1" >> config.mk && \
#     echo "USE_ZLIB = 1" >> config.mk && \
#     echo "USE_SSL = 1" >> config.mk && \
#     echo "GIT_EXECUTABLE = /usr/bin/git" >> config.mk

# Compile
RUN make

# -----------------------------------------------------------------------------
# Stage 2: Runtime Stage
# -----------------------------------------------------------------------------
FROM alpine:3.22

# Install runtime dependencies
RUN set -xe && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        git gitolite git-daemon openssh \
        nginx fcgiwrap spawn-fcgi \
        openssl zlib \
        python3 py3-markdown py3-pygments \
        lzip xz zstd gzip bzip2 \
        tini && \
    mkdir -p /run/nginx /var/www/localhost/htdocs/cgit /usr/lib/cgit/filters/html-converters && \
    rm -rf /var/cache/apk/* /tmp/*

# Copy compiled binaries and static assets
COPY --from=cgit_builder /usr/src/cgit/cgit.cgi /usr/bin/cgit.cgi
COPY --from=cgit_builder /usr/src/cgit/cgit.css /var/www/localhost/htdocs/cgit/cgit.css
COPY --from=cgit_builder /usr/src/cgit/cgit.png /var/www/localhost/htdocs/cgit/cgit.png

# Copy user-supplied scripts
COPY cgit.css /var/www/localhost/htdocs/cgit/cgit.css
COPY md2html /usr/lib/cgit/filters/html-converters/md2html
COPY syntax-highlighting.py /usr/lib/cgit/filters/html-converters/syntax-highlighting.py
COPY auto-default-branch.sh /usr/lib/gitolite/triggers/auto-default-branch
COPY entrypoint.sh /

# Set permissions
RUN chmod +x /usr/lib/cgit/filters/html-converters/md2html \
    /usr/lib/cgit/filters/html-converters/syntax-highlighting.py \
    /usr/lib/gitolite/triggers/auto-default-branch \
    /entrypoint.sh /usr/bin/cgit.cgi

# Volumes for persistence
VOLUME ["/etc/ssh", "/var/lib/git"]

# Expose ports
EXPOSE 22 80 9418

# Working directory
WORKDIR /var/lib/git

# Use tini as init for signal handling
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
