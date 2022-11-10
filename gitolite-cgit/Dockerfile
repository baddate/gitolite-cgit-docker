# -----------------------------------------------------------------------------
# Stage 1: Build cgit from source
# -----------------------------------------------------------------------------
FROM alpine:3.22 AS cgit_builder
LABEL stage=cgit_builder

# Install build tools and development libraries
RUN apk add --no-cache \
    build-base git openssl-dev zlib-dev lua5.3-dev asciidoc pkgconfig gettext-dev curl xz

WORKDIR /usr/src

# Download cgit latest source (master branch)
RUN curl -LO https://git.zx2c4.com/cgit/snapshot/cgit-09d24d7cd0b7e85633f2f43808b12871bb209d69.tar.xz && \
    tar xJf cgit-09d24d7cd0b7e85633f2f43808b12871bb209d69.tar.xz && \
    mv cgit-09d24d7cd0b7e85633f2f43808b12871bb209d69 cgit

WORKDIR /usr/src/cgit

# Compile cgit with proper build options (from APKBUILD)
RUN make NO_ICONV=YesPlease \
         NO_GETTEXT=YesPlease \
         NO_TCLTK=YesPlease \
         NO_SVN_TESTS=YesPlease \
         NO_REGEX=NeedsStartEnd \
         LUA_PKGCONFIG=lua5.3 \
         prefix=/usr

# -----------------------------------------------------------------------------
# Stage 2: Runtime Stage
# -----------------------------------------------------------------------------
FROM alpine:3.22

# Install runtime dependencies (including lua5.3 for cgit runtime)
RUN set -xe && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        git gitolite git-daemon openssh \
        nginx fcgiwrap spawn-fcgi \
        openssl zlib lua5.3 \
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
