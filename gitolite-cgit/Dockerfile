# syntax=docker/dockerfile:1.4
# -----------------------------------------------------------------------------
# Stage 1: Build cgit from source (following official README with git clone)
# -----------------------------------------------------------------------------
FROM alpine:3.23 AS cgit_builder
LABEL stage=cgit_builder

ARG CGIT_VER=cgit-1.3
ARG CGIT_URL=https://git.zx2c4.com/cgit/snapshot
ARG GIT_VER=2.53.0

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

RUN --mount=type=cache,target=/usr/src/cgit-archive,sharing=locked \
    set -eux && \
    ENC_VER="$(printf '%s' "$CGIT_VER" | sed -e 's/%/%25/g' -e 's:/:%2F:g')" && \
    ENC_VER_DASH="$(printf '%s' "$CGIT_VER" | sed -e 's/%/%25/g' -e 's:/:-:g')" && \
    ARCHIVE="/usr/src/cgit-archive/${ENC_VER_DASH}.tar.xz" && \
    if [ ! -f "$ARCHIVE" ]; then \
        curl -fL "${CGIT_URL%/}/${ENC_VER}.tar.xz" -o "$ARCHIVE"; \
    fi && \
    tar xf "$ARCHIVE" -C /usr/src && \
    mv "/usr/src/${CGIT_VER}" /usr/src/cgit

WORKDIR /usr/src/cgit

# Compile cgit with build options optimized for Alpine
RUN set -eux && \
    make get-git GIT_VER=${GIT_VER} && \
    make all \
      NO_GETTEXT=YesPlease \
      NO_REGEX=NeedsStartEnd \
      LUA_PKGCONFIG=lua5.3 \
      GIT_VER=${GIT_VER}

RUN set -eux; \
    before_bytes="$(stat -c '%s' cgit)"; \
    echo "cgit size before strip: ${before_bytes} bytes"; \
    ls -lh cgit; \
    strip cgit; \
    after_bytes="$(stat -c '%s' cgit)"; \
    echo "cgit size after strip:  ${after_bytes} bytes"; \
    echo "cgit size reduced:     $((before_bytes - after_bytes)) bytes"; \
    ls -lh cgit

# -----------------------------------------------------------------------------
# Stage 2: Runtime Stage
# -----------------------------------------------------------------------------
FROM alpine:3.23 AS runtime

# Install runtime dependencies
RUN set -e && \
    apk add --no-cache \
        # Runtime essentials
        tini \
        openssl \
        zlib \
        lua5.3 \
        # Git & gitolite stack
        git \
        gitolite \
        git-daemon \
        openssh \
        # Web server & CGI
        nginx \
        fcgiwrap \
        spawn-fcgi \
        # Syntax highlighting (python3 + pygments + markdown)
        python3 \
        py3-markdown \
        py3-pygments \
        # Compression tools (cgit snapshots)
        lzip \
        xz \
        zstd \
        gzip \
        bzip2 && \
    mkdir -p /run/nginx /var/www/htdocs/cgit /usr/lib/cgit/filters /usr/local/lib/cgit && \
    rm -rf /var/cache/apk/* /tmp/*

# -----------------------------------------------------------------------------
# Layer ordering: COPY instructions grouped by change frequency (slowest first)
# -----------------------------------------------------------------------------

# 1. Compiler builder assets (slowest, only changes on cgit version bump)
COPY --from=cgit_builder /usr/src/cgit/cgit /var/www/htdocs/cgit/cgit
COPY --from=cgit_builder /usr/src/cgit/cgit.css /var/www/htdocs/cgit/cgit.css
COPY --from=cgit_builder /usr/src/cgit/cgit.png /var/www/htdocs/cgit/cgit.png
COPY --from=cgit_builder /usr/src/cgit/cgit.js /var/www/htdocs/cgit/cgit.js
COPY --from=cgit_builder /usr/src/cgit/favicon.ico /var/www/htdocs/cgit/favicon.ico
COPY --from=cgit_builder /usr/src/cgit/robots.txt /var/www/htdocs/cgit/robots.txt
COPY --from=cgit_builder /usr/src/cgit/filters/ /usr/lib/cgit/filters/

# 2. Custom themes (medium, changes when restyling)
COPY cgit.css /var/www/htdocs/cgit/cgit.css
COPY md2html /usr/lib/cgit/filters/html-converters/md2html
COPY syntax-highlighting.py /usr/lib/cgit/filters/syntax-highlighting.py
COPY catppuccin_mocha.py /usr/local/lib/cgit/catppuccin_mocha.py
COPY catppuccin_macchiato.py /usr/local/lib/cgit/catppuccin_macchiato.py
COPY catppuccin_latte.py /usr/local/lib/cgit/catppuccin_latte.py

# 3. Gitolite triggers (medium)
COPY auto-default-branch.sh /usr/lib/gitolite/triggers/auto-default-branch
COPY set-master-branch.sh /usr/lib/gitolite/triggers/set-master-branch

# 4. Entrypoint (fastest, changes most frequently)
COPY entrypoint.sh /

# Set permissions and symlinks
RUN chmod 0755 /var/www/htdocs/cgit/cgit && \
    chown -R root:nginx /var/www/htdocs/cgit && \
    chmod 0644 /var/www/htdocs/cgit/cgit.css \
               /var/www/htdocs/cgit/cgit.png \
               /var/www/htdocs/cgit/cgit.js \
               /var/www/htdocs/cgit/favicon.ico \
               /var/www/htdocs/cgit/robots.txt && \
    chmod -R 0755 /usr/lib/cgit/filters/ && \
    ln -snf /var/www/htdocs/cgit/cgit /var/www/htdocs/cgit/cgit.cgi && \
    chmod u+x /usr/lib/cgit/filters/html-converters/md2html \
        /usr/lib/cgit/filters/syntax-highlighting.py \
        /entrypoint.sh && \
    chmod a+x /usr/lib/gitolite/triggers/auto-default-branch \
        /usr/lib/gitolite/triggers/set-master-branch

# Volumes for persistence
VOLUME ["/etc/ssh", "/var/lib/git"]

# Expose ports
#   SSH (gitolite)
EXPOSE 22
#   HTTP (cgit web UI)
EXPOSE 80
#   Git daemon protocol (anonymous fetch)
EXPOSE 9418

# Working directory
WORKDIR /var/lib/git

# Use tini as init for signal handling
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
