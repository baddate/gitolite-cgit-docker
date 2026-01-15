# -----------------------------------------------------------------------------
# Stage 1: Build cgit from source (following official README with git clone)
# -----------------------------------------------------------------------------
FROM alpine:3.22 AS cgit_builder
LABEL stage=cgit_builder

# Install build tools and development libraries
# Dependencies based on cgit README: libzip, libcrypto (OpenSSL), libssl (OpenSSL)
RUN apk add --no-cache \
    build-base \
    openssl-dev \
    zlib-dev \
    libzip-dev \
    lua5.3-dev \
    pkgconfig \
    curl

WORKDIR /usr/src

RUN curl -LO https://git.zx2c4.com/cgit/snapshot/cgit-master.tar.xz && \
    tar xf cgit-master.tar.xz && \
    mv cgit-master cgit

WORKDIR /usr/src/cgit

# Compile cgit with build options optimized for Alpine
RUN echo "NO_GETTEXT=YesPlease" >> build.opts && \
    echo "NO_REGEX=NeedsStartEnd" >> build.opts && \
    echo "LUA_PKGCONFIG=lua5.3" >> build.opts && \
    make get-git && \
    make $(cat build.opts) all

# -----------------------------------------------------------------------------
# Stage 2: Runtime Stage
# -----------------------------------------------------------------------------
FROM alpine:3.22

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories

# Install runtime dependencies
RUN set -e && \
    apk add --no-cache \
        git \
        gitolite \
        git-daemon \
        openssh>=10 \
        nginx \
        fcgiwrap \
        spawn-fcgi \
        openssl \
        zlib \
        lua5.3 \
        python3 \
        py3-markdown \
        py3-pygments \
        lzip \
        xz \
        zstd \
        gzip \
        bzip2 \
        tini && \
    mkdir -p /run/nginx /var/www/htdocs/cgit /usr/lib/cgit/filters && \
    rm -rf /var/cache/apk/* /tmp/*

# Copy compiled binaries and static assets
COPY --from=cgit_builder /usr/src/cgit/cgit /var/www/htdocs/cgit/cgit.cgi
COPY --from=cgit_builder /usr/src/cgit/cgit.css /var/www/htdocs/cgit/cgit.css
COPY --from=cgit_builder /usr/src/cgit/cgit.png /var/www/htdocs/cgit/cgit.png
COPY --from=cgit_builder /usr/src/cgit/cgit.js /var/www/htdocs/cgit/cgit.js
COPY --from=cgit_builder /usr/src/cgit/favicon.ico /var/www/htdocs/cgit/favicon.ico
COPY --from=cgit_builder /usr/src/cgit/robots.txt /var/www/htdocs/cgit/robots.txt

# Copy filters directory from cgit source
COPY --from=cgit_builder /usr/src/cgit/filters/ /usr/lib/cgit/filters/

# Set proper permissions to match make install
RUN chmod 0755 /var/www/htdocs/cgit/cgit.cgi && \
    chmod 0644 /var/www/htdocs/cgit/cgit.css \
               /var/www/htdocs/cgit/cgit.png \
               /var/www/htdocs/cgit/cgit.js \
               /var/www/htdocs/cgit/favicon.ico \
               /var/www/htdocs/cgit/robots.txt && \
    chmod -R 0755 /usr/lib/cgit/filters/

# Copy user-supplied scripts
COPY cgit.css /usr/share/webapps/cgit/cgit.css
COPY cgit.css /var/www/htdocs/cgit/cgit.css
COPY md2html /usr/lib/cgit/filters/html-converters/md2html
COPY syntax-highlighting.py /usr/lib/cgit/filters/html-converters/syntax-highlighting.py
COPY auto-default-branch.sh /usr/lib/gitolite/triggers/auto-default-branch
COPY entrypoint.sh /

# Set permissions for user-supplied scripts
RUN chmod +x /usr/lib/cgit/filters/html-converters/md2html \
    /usr/lib/cgit/filters/html-converters/syntax-highlighting.py \
    /usr/lib/gitolite/triggers/auto-default-branch \
    /entrypoint.sh

# Volumes for persistence
VOLUME ["/etc/ssh", "/var/lib/git"]

# Expose ports
EXPOSE 22 80 9418

# Working directory
WORKDIR /var/lib/git

# Use tini as init for signal handling
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
