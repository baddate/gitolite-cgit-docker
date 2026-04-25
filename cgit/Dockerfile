# syntax=docker/dockerfile:1.7
# -----------------------------------------------------------------------------
# Stage 1: Build cgit from source (following official README with git clone)
# -----------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM alpine:3.23 AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Alpine uses busybox ash (not POSIX sh) — needed for pipefail support
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ARG CGIT_VER=cgit-1.3
ARG CGIT_URL=https://git.zx2c4.com/cgit/snapshot
ARG GIT_VER=2.53.0

# Install build tools and development libraries
# Dependencies based on cgit README: libzip, libcrypto (OpenSSL), libssl (OpenSSL)
RUN apk add --no-cache \
    build-base \
    openssl-dev \
    zlib-dev \
    lua5.3-dev \
    pkgconf \
    curl \
    curl-dev \
    expat-dev

WORKDIR /usr/src

# -----------------------------------------------------------------------------
# cgit source (cache)
# -----------------------------------------------------------------------------
RUN --mount=type=cache,id=cgit-cache,target=/usr/src/cgit-archive,sharing=locked \
    set -euxo pipefail && \
    ENC_VER="$(printf '%s' "$CGIT_VER" | sed -e 's/%/%25/g' -e 's:/:%2F:g')" && \
    ENC_VER_DASH="$(printf '%s' "$CGIT_VER" | sed -e 's/%/%25/g' -e 's:/:-:g')" && \
    ARCHIVE="/usr/src/cgit-archive/${ENC_VER_DASH}.tar.xz" && \
    if [ ! -f "$ARCHIVE" ]; then \
        curl -fSL --retry 3 "${CGIT_URL%/}/${ENC_VER}.tar.xz" -o "$ARCHIVE"; \
    fi && \
    tar xf "$ARCHIVE" -C /usr/src && \
    mv "/usr/src/${CGIT_VER}" /usr/src/cgit

# -----------------------------------------------------------------------------
# git source + build (cache)
# -----------------------------------------------------------------------------
ENV GIT_BUILD_OPTS="\
  NO_GETTEXT=YesPlease \
  NO_TCLTK=YesPlease \
  NO_REGEX=YesPlease \
  NO_PERL=YesPlease \
  NO_PYTHON=YesPlease \
  NO_INSTALL_HARDLINKS=YesPlease \
  INSTALL_SYMLINKS=1"

ENV CFLAGS="-Os -fomit-frame-pointer -flto=auto"
ENV LDFLAGS="-Wl,--as-needed -flto=auto"

RUN --mount=type=cache,id=git-cache,target=/usr/src/git-archive,sharing=locked \
    set -eux && \
    GIT_TGZ="/usr/src/git-archive/git-${GIT_VER}.tar.xz" && \
    if [ ! -f "$GIT_TGZ" ]; then \
        curl -fSL --retry 3 \
          "https://www.kernel.org/pub/software/scm/git/git-${GIT_VER}.tar.xz" \
          -o "$GIT_TGZ"; \
    fi && \
    tar xf "$GIT_TGZ" -C /usr/src && \
    cd "/usr/src/git-${GIT_VER}" && \
    make prefix=/usr/local all $GIT_BUILD_OPTS && \
    make prefix=/usr/local install $GIT_BUILD_OPTS

# -----------------------------------------------------------------------------
# build cgit
# -----------------------------------------------------------------------------
WORKDIR /usr/src/cgit

RUN set -eux && \
    rm -rf git && \
    cp -r "/usr/src/git-${GIT_VER}" git && \
    make all \
      NO_GETTEXT=YesPlease \
      NO_REGEX=NeedsStartEnd \
      LUA_PKGCONFIG=lua5.3 \
      GIT_VER=${GIT_VER}

RUN set -eux && \
    strip cgit

# strip git binaries
RUN set -eux && \
    # strip binaries
    find /usr/local -type f -exec file {} \; | grep ELF | cut -d: -f1 | xargs -r strip && \
    # remove unnecessary files
    rm -rf \
      /usr/local/share \
      /usr/local/include \
      /usr/local/lib/pkgconfig

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
LABEL org.opencontainers.image.title="cgit"
LABEL org.opencontainers.image.description="Docker image with cgit in dark-mode on Alpine"
LABEL org.opencontainers.image.url="https://github.com/baddate/gitolite-cgit-docker"
LABEL org.opencontainers.image.source="https://github.com/baddate/gitolite-cgit-docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"

# Install runtime dependencies
RUN set -e && \
    apk add --no-cache \
        # Runtime essentials
        tini \
        lua5.3 \
        expat \
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
    mkdir -p /run/nginx /var/www/htdocs/cgit /usr/lib/cgit/filters /usr/local/lib/cgit /var/cache/cgit && \
    rm -rf /var/cache/apk/* /tmp/*

# -----------------------------------------------------------------------------
# Layer ordering: COPY instructions grouped by change frequency (slowest first)
# -----------------------------------------------------------------------------

# 1. Compiler builder assets (slowest, only changes on cgit version bump)
COPY --from=builder /usr/local/bin/git /usr/local/bin/git
COPY --from=builder /usr/local/libexec/git-core /usr/local/libexec/git-core

RUN rm -rf \
  /usr/local/libexec/git-core/git-http-* \
  /usr/local/libexec/git-core/git-remote-* \
  /usr/local/libexec/git-core/git-svn* \
  /usr/local/libexec/git-core/git-p4* \
  /usr/local/libexec/git-core/git-cvs*

ENV PATH="/usr/local/bin:/usr/local/libexec/git-core:$PATH"
ENV GIT_EXEC_PATH=/usr/local/libexec/git-core

RUN sed -i 's/^user/#user/' /etc/nginx/nginx.conf

COPY --from=builder /usr/src/cgit/cgit /var/www/htdocs/cgit/cgit
COPY --from=builder /usr/src/cgit/cgit.css /var/www/htdocs/cgit/cgit.css
COPY --from=builder /usr/src/cgit/cgit.png /var/www/htdocs/cgit/cgit.png
COPY --from=builder /usr/src/cgit/cgit.js /var/www/htdocs/cgit/cgit.js
COPY --from=builder /usr/src/cgit/favicon.ico /var/www/htdocs/cgit/favicon.ico
COPY --from=builder /usr/src/cgit/robots.txt /var/www/htdocs/cgit/robots.txt
COPY --from=builder /usr/src/cgit/filters/ /usr/lib/cgit/filters/

# 2. Custom themes (medium, changes when restyling)
COPY cgit.css /var/www/htdocs/cgit/cgit.css
COPY md2html /usr/lib/cgit/filters/html-converters/md2html
COPY syntax-highlighting.py /usr/lib/cgit/filters/syntax-highlighting.py
COPY catppuccin_mocha.py /usr/local/lib/cgit/catppuccin_mocha.py
COPY catppuccin_macchiato.py /usr/local/lib/cgit/catppuccin_macchiato.py
COPY catppuccin_latte.py /usr/local/lib/cgit/catppuccin_latte.py
COPY cgitrc.template      /usr/local/share/cgitrc.template
COPY nginx-cgit.conf      /usr/local/share/nginx-cgit.conf

# 3. Entrypoint (fastest, changes most frequently)
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
        /entrypoint.sh

#   HTTP (cgit web UI)
EXPOSE 80

# Use tini as init for signal handling
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]