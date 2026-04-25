# syntax=docker/dockerfile:1.7
# -----------------------------------------------------------------------------
# Stage 1: Build cgit from source
# -----------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM alpine:3.23 AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETARCH

SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

ARG CGIT_VER=cgit-1.3
ARG CGIT_URL=https://git.zx2c4.com/cgit/snapshot
ARG GIT_VER=2.53.0

RUN apk add --no-cache \
    build-base \
    openssl-dev \
    zlib-dev \
    lua5.4-dev \
    pkgconf \
    curl \
    expat-dev

WORKDIR /usr/src

# -----------------------------------------------------------------------------
# cgit source (cached per-arch)
# -----------------------------------------------------------------------------
RUN --mount=type=cache,id=cgit-cache-${TARGETARCH},target=/usr/src/cgit-archive,sharing=locked \
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
# git source + build (cached per-arch)
# -----------------------------------------------------------------------------
ENV GIT_BUILD_OPTS="\
  NO_GETTEXT=YesPlease \
  NO_TCLTK=YesPlease \
  NO_CURL=YesPlease \
  NO_REGEX=YesPlease \
  NO_PERL=YesPlease \
  NO_PYTHON=YesPlease \
  NO_INSTALL_HARDLINKS=YesPlease \
  INSTALL_SYMLINKS=1"

ENV CFLAGS="-Os -fomit-frame-pointer -ffunction-sections -fdata-sections -flto=auto"
ENV LDFLAGS="-Wl,--gc-sections -Wl,--as-needed -flto=auto"

RUN --mount=type=cache,id=git-cache-${TARGETARCH},target=/usr/src/git-archive,sharing=locked \
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
# FIX: symlink instead of cp -r — avoids copying ~50MB git source tree
# -----------------------------------------------------------------------------
WORKDIR /usr/src/cgit

RUN set -eux && \
    rm -rf git && \
    cp -al "/usr/src/git-${GIT_VER}" git && \
    make all \
      NO_GETTEXT=YesPlease \
      NO_REGEX=NeedsStartEnd \
      LUA_PKGCONFIG=lua5.4 \
      GIT_VER=${GIT_VER}

# FIX: merged strip + cleanup into one RUN layer
# FIX: batched file(1) via xargs for speed (avoids per-file fork)
RUN set -eux && \
    strip cgit && \
    find /usr/local -type f | xargs -r file | grep ELF | cut -d: -f1 | xargs -r strip && \
    rm -rf \
      /usr/local/share \
      /usr/local/include \
      /usr/local/lib/pkgconfig

# -----------------------------------------------------------------------------
# Stage 2: Runtime
# -----------------------------------------------------------------------------
FROM alpine:3.23 AS runtime

# FIX: SHELL in runtime stage for consistent error behaviour
SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

ARG BUILD_DATE
ARG REVISION
ARG VERSION=latest

LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.revision=${REVISION}
LABEL org.opencontainers.image.version=${VERSION}
LABEL org.opencontainers.image.title="cgit"
LABEL org.opencontainers.image.description="Docker image with cgit in dark-mode on Alpine"
LABEL org.opencontainers.image.url="https://github.com/baddate/gitolite-cgit-docker"
LABEL org.opencontainers.image.source="https://github.com/baddate/gitolite-cgit-docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"

# FIX: removed `gzip` — busybox already provides it
# py3-markdown kept — required by md2html filter
RUN apk add --no-cache \
        tini \
        lua5.4 \
        expat \
        nginx \
        fcgiwrap \
        spawn-fcgi \
        python3 \
        py3-markdown \
        py3-pygments \
        lzip \
        xz \
        zstd \
        bzip2 && \
    mkdir -p \
        /run/nginx \
        /var/www/htdocs/cgit \
        /usr/lib/cgit/filters \
        /usr/local/lib/cgit \
        /var/cache/cgit && \
    rm -rf /var/cache/apk/* /tmp/*

# -----------------------------------------------------------------------------
# Builder assets — slowest layer, only changes on version bump
# -----------------------------------------------------------------------------
COPY --from=builder /usr/local/bin/git /usr/local/bin/

COPY --from=builder \
    /usr/local/libexec/git-core/git-cat-file \
    /usr/local/libexec/git-core/git-rev-list \
    /usr/local/libexec/git-core/git-rev-parse \
    /usr/local/libexec/git-core/git-diff-tree \
    /usr/local/libexec/git-core/git-for-each-ref \
    /usr/local/libexec/git-core/git-read-tree \
    /usr/local/libexec/git-core/

ENV PATH="/usr/local/bin:/usr/local/libexec/git-core:$PATH"
ENV GIT_EXEC_PATH=/usr/local/libexec/git-core

COPY --from=builder /usr/src/cgit/cgit        /var/www/htdocs/cgit/cgit
COPY --from=builder /usr/src/cgit/cgit.css    /var/www/htdocs/cgit/cgit.css
COPY --from=builder /usr/src/cgit/cgit.png    /var/www/htdocs/cgit/cgit.png
COPY --from=builder /usr/src/cgit/cgit.js     /var/www/htdocs/cgit/cgit.js
COPY --from=builder /usr/src/cgit/favicon.ico /var/www/htdocs/cgit/favicon.ico
COPY --from=builder /usr/src/cgit/robots.txt  /var/www/htdocs/cgit/robots.txt
COPY --from=builder /usr/src/cgit/filters/    /usr/lib/cgit/filters/

# -----------------------------------------------------------------------------
# Custom theme / filters — medium frequency
# -----------------------------------------------------------------------------
COPY cgit.css                /var/www/htdocs/cgit/cgit.css
COPY md2html                 /usr/lib/cgit/filters/html-converters/md2html
COPY syntax-highlighting.py  /usr/lib/cgit/filters/syntax-highlighting.py
COPY catppuccin_mocha.py     /usr/local/lib/cgit/catppuccin_mocha.py
COPY catppuccin_macchiato.py /usr/local/lib/cgit/catppuccin_macchiato.py
COPY catppuccin_latte.py     /usr/local/lib/cgit/catppuccin_latte.py
COPY cgitrc.template         /usr/local/share/cgitrc.template
COPY nginx-cgit.conf         /usr/local/share/nginx-cgit.conf

RUN rm -f /etc/nginx/http.d/default.conf

# -----------------------------------------------------------------------------
# Entrypoint — changes most frequently
# -----------------------------------------------------------------------------
COPY entrypoint.sh /entrypoint.sh

# FIX: /var/cache/cgit owned by fcgiwrap so cgit can write cache entries
# FIX: removed dead rm of git-http-*/git-remote-* (never copied into runtime)
RUN chmod 0755 /var/www/htdocs/cgit/cgit && \
    chown -R root:nginx /var/www/htdocs/cgit && \
    chown fcgiwrap:nginx /var/cache/cgit && \
    chmod 0755 /var/cache/cgit && \
    chmod 0644 \
        /var/www/htdocs/cgit/cgit.css \
        /var/www/htdocs/cgit/cgit.png \
        /var/www/htdocs/cgit/cgit.js \
        /var/www/htdocs/cgit/favicon.ico \
        /var/www/htdocs/cgit/robots.txt && \
    chmod -R 0755 /usr/lib/cgit/filters/ && \
    ln -snf /var/www/htdocs/cgit/cgit /var/www/htdocs/cgit/cgit.cgi && \
    ln -snf /var/lib/git/cgitrc /etc/cgitrc && \
    chmod u+x \
        /usr/lib/cgit/filters/html-converters/md2html \
        /usr/lib/cgit/filters/syntax-highlighting.py \
        /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]