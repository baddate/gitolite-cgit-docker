# syntax=docker/dockerfile:1.4
# -----------------------------------------------------------------------------
# Stage 1: Build cgit from source (following official README with git clone)
# -----------------------------------------------------------------------------
FROM alpine:3.23 AS cgit_builder
LABEL stage=cgit_builder

# Alpine uses busybox ash (not POSIX sh) — needed for pipefail support
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ARG CGIT_VER=cgit-1.3
ARG CGIT_URL=https://git.zx2c4.com/cgit/snapshot
ARG GIT_VER=2.52.0

# Install build tools and development libraries
# Dependencies based on cgit README: libzip, libcrypto (OpenSSL), libssl (OpenSSL)
RUN apk add --no-cache \
    build-base=0.5-r3 \
    openssl-dev=3.5.6-r0 \
    zlib-dev=1.3.2-r0 \
    libzip-dev=1.11.4-r1 \
    lua5.3-dev=5.3.6-r6 \
    pkgconf=2.5.1-r0 \
    curl=8.17.0-r1

WORKDIR /usr/src

RUN --mount=type=cache,target=/usr/src/cgit-archive,sharing=locked \
    set -euxo pipefail && \
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

# Build arguments for OCI labels
ARG BUILD_DATE
ARG REVISION
ARG VERSION=latest

# OCI image labels for provenance tracking
LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.revision=${REVISION}
LABEL org.opencontainers.image.version=${VERSION}
LABEL org.opencontainers.image.title="gitolite-cgit"
LABEL org.opencontainers.image.description="Docker image with cgit in dark-mode and gitolite on Alpine"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/rusian/gitolite-cgit"
LABEL org.opencontainers.image.source="https://github.com/baddate/gitolite-cgit-docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"

# Install runtime dependencies
RUN set -e && \
    apk add --no-cache \
        # Runtime essentials
        tini=0.19.0-r3 \
        openssl=3.5.6-r0 \
        zlib=1.3.2-r0 \
        lua5.3=5.3.6-r6 \
        # Git & gitolite stack
        git=2.52.0-r0 \
        gitolite=3.6.14-r0 \
        git-daemon=2.52.0-r0 \
        openssh=10.2_p1-r0 \
        # Web server & CGI
        nginx=1.28.3-r0 \
        fcgiwrap=1.1.0-r9 \
        spawn-fcgi=1.6.6-r0 \
        # Syntax highlighting (python3 + pygments + markdown)
        python3=3.12.13-r0 \
        py3-markdown=3.10.0-r0 \
        py3-pygments=2.19.2-r0 \
        # Compression tools (cgit snapshots)
        lzip=1.25-r0 \
        xz=5.8.2-r0 \
        zstd=1.5.7-r2 \
        gzip=1.14-r2 \
        bzip2=1.0.8-r6 && \
    mkdir -p /run/nginx /var/www/htdocs/cgit /usr/lib/cgit/filters /usr/local/lib/cgit /var/cache/cgit && \
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
    # /etc/cgitrc is on the read-only rootfs at runtime.
    # Create a symlink in the image layer pointing to the git volume so
    # entrypoint can write /var/lib/git/cgitrc without touching /etc.
    ln -snf /var/lib/git/cgitrc /etc/cgitrc && \
    chmod u+x /usr/lib/cgit/filters/html-converters/md2html \
        /usr/lib/cgit/filters/syntax-highlighting.py \
        /entrypoint.sh && \
    chmod a+x /usr/lib/gitolite/triggers/auto-default-branch \
        /usr/lib/gitolite/triggers/set-master-branch

# Create dedicated runtime user (for nginx foreground process)
# Add to nginx group so cgit user can access fcgiwrap socket
RUN adduser -D -u 1001 cgit && adduser cgit nginx && \
    # Pre-add nginx and fcgiwrap to the git group so entrypoint doesn't need
    # to modify /etc/group at runtime (read-only rootfs compatibility)
    adduser nginx git && \
    adduser fcgiwrap git

# Install su-exec for privilege dropping in entrypoint
RUN apk add --no-cache su-exec=0.3-r0

# Remove setuid/setgid bits — not needed in container context
# EXCLUDE su-exec: it needs setuid to drop privileges at runtime
RUN find / \( -path /usr/sbin/su-exec -o -path /sbin/su-exec \) -prune \
    -o -perm /6000 -type f -exec chmod a-s {} \; 2>/dev/null || true

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

# Health check: verify nginx/cgit responds on port 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Use tini as init for signal handling
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]