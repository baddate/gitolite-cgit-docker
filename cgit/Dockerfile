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
ARG CGIT_CONFIG=/run/cgitrc
ARG CACHE_ROOT=/run/cgit-cache

# openssl-dev: required by cgit (MD5 for ETag + Gravatar)
# expat-dev: required by git's mailinfo/patch parsing linked into cgit
# pkgconf: required to detect lua5.4 via pkg-config
RUN apk add --no-cache \
    build-base \
    openssl-dev \
    zlib-dev \
    lua5.4-dev \
    pcre2-dev \
    pkgconf \
    curl

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
# git source (cached per-arch) — extracted only, not built standalone.
# cgit's Makefile builds the git subset it needs internally via cgit.mk.
# -----------------------------------------------------------------------------
RUN --mount=type=cache,id=git-cache-${TARGETARCH},target=/usr/src/git-archive,sharing=locked \
    set -eux && \
    GIT_TGZ="/usr/src/git-archive/git-${GIT_VER}.tar.xz" && \
    if [ ! -f "$GIT_TGZ" ]; then \
        curl -fSL --retry 3 \
          "https://www.kernel.org/pub/software/scm/git/git-${GIT_VER}.tar.xz" \
          -o "$GIT_TGZ"; \
    fi && \
    tar xf "$GIT_TGZ" -C /usr/src

# -----------------------------------------------------------------------------
# Build cgit (which builds the git subset it needs internally via cgit.mk)
#
# Flag rationale:
#   NO_GETTEXT    — cgit has no i18n
#   NO_TCLTK      — no Tcl/Tk in a CGI
#   NO_ICONV      — cgit never re-encodes text; git needs iconv only for that
#   NO_EXPAT      — git uses expat only for http-push/svn; cgit does neither
#   NO_REGEX      — cgit doesn't call regcomp; uses a tiny compat stub instead
#   NO_CURL       — cgit.mk already forces NO_CURL=1; explicit for clarity
#   LUA_PKGCONFIG — pin to lua5.4; prevents auto-detecting a wrong version
#
# Removed vs. previous version:
#   NO_SVN_TESTS        — test-only flag, no effect on compiled output
#   NO_PERL/NO_PYTHON   — not recognised by cgit.mk
#   NO_LIBPCRE/USE_LIBPCRE2 — cgit log search uses fixed-string grep; PCRE
#                             adds a dependency with no user-visible benefit
#   NO_INSTALL_HARDLINKS/INSTALL_SYMLINKS — irrelevant; we don't install git
#
# FIX: cp -al (hard-link copy) not ln -s — cgit Makefile resolves `..`
# relative to the real path, not the symlink target.
# -----------------------------------------------------------------------------
WORKDIR /usr/src/cgit

ENV CFLAGS="-Os -fomit-frame-pointer -ffunction-sections -fdata-sections -flto=auto"
ENV LDFLAGS="-Wl,--gc-sections -Wl,--as-needed -flto=auto"

COPY cgit-scp-clone-url.patch /usr/src/cgit/
RUN set -eux && \
    rm -rf git && \
    cp -al "/usr/src/git-${GIT_VER}" git && \
    patch -p1 < cgit-scp-clone-url.patch && \
    make all \
      NO_GETTEXT=YesPlease \
      NO_TCLTK=YesPlease \
      NO_ICONV=YesPlease \
      NO_EXPAT=YesPlease \
      NO_REGEX=NeedsStartEnd \
      USE_LIBPCRE2=YesPlease \
      NO_CURL=YesPlease \
      LUA_PKGCONFIG=lua5.4 \
      GIT_VER=${GIT_VER} \
      CGIT_CONFIG=${CGIT_CONFIG} \
      CACHE_ROOT=${CACHE_ROOT}

RUN set -eux && strip cgit

# -----------------------------------------------------------------------------
# Stage 2: Runtime
# -----------------------------------------------------------------------------
FROM alpine:3.23 AS runtime

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

# Compression tools called as child processes by cgit's snapshot code:
#   gzip  — busybox already provides it (handles tar.gz)
#   bzip2 — tar.bz2
#   xz    — tar.xz
#   zstd  — tar.zst
#   lzip  — tar.lz
# py3-markdown: required by md2html about-filter
# py3-pygments: required by syntax-highlighting.py source-filter
RUN apk add --no-cache \
        tini \
        lua5.4 \
        lua5.4-ossl \
        pcre2 \
        socat \
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
        /var/lib/nginx/logs && \
    rm -rf /var/cache/apk/* /tmp/* && \
    rm -f /etc/nginx/http.d/default.conf

# ── Groups only — no git user needed in this container ───────────────────────
# gitrepos(GID 2000): shared read-access group for git repositories.
#   Must match GID 2000 in the gitolite container (enforced by -g 2000).
# nginx group: fcgiwrap joins so nginx can access the fcgiwrap socket.
RUN addgroup -g 2000 gitrepos && \
    addgroup fcgiwrap gitrepos && \
    addgroup fcgiwrap nginx

# -----------------------------------------------------------------------------
# Builder assets — slowest layer, only changes on version bump
# -----------------------------------------------------------------------------
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
COPY cgitrc.template         /usr/local/share/cgitrc.template
COPY filters/md2html                 /usr/lib/cgit/filters/html-converters/md2html
COPY filters/syntax-highlighting.py  /usr/lib/cgit/filters/syntax-highlighting.py
COPY theme/catppuccin_mocha.py     /usr/local/lib/cgit/catppuccin_mocha.py
COPY theme/catppuccin_macchiato.py /usr/local/lib/cgit/catppuccin_macchiato.py
COPY theme/catppuccin_latte.py     /usr/local/lib/cgit/catppuccin_latte.py
COPY nginx/cgit.conf         /etc/nginx/http.d/cgit.conf
COPY nginx/default.conf      /etc/nginx/nginx.conf

# -----------------------------------------------------------------------------
# Entrypoint — changes most frequently
# -----------------------------------------------------------------------------
COPY entrypoint.sh /entrypoint.sh

RUN chmod 0755 /var/www/htdocs/cgit/cgit && \
    chown -R fcgiwrap:nginx /var/www/htdocs/cgit && \
    chown -R fcgiwrap:nginx /usr/lib/cgit/filters/ && \
    chmod -R 0755 /usr/lib/cgit/filters/ && \
    ln -snf /var/www/htdocs/cgit/cgit /var/www/htdocs/cgit/cgit.cgi && \
    chmod +x \
        /usr/lib/cgit/filters/html-converters/md2html \
        /usr/lib/cgit/filters/syntax-highlighting.py \
        /usr/lib/cgit/filters/commit-links.sh \
        /usr/lib/cgit/filters/email-libravatar.lua \
        /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]