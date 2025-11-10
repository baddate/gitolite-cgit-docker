# -----------------------------------------------------------------------------
# Stage 1: Cgit Builder Stage
# This stage installs development packages and compiles cgit from source.
# -----------------------------------------------------------------------------
FROM alpine:latest AS cgit_builder
LABEL stage=cgit_builder

# Install build tools and development libraries needed for cgit compilation.
# build-base: Includes gcc, make, libc-dev.
# git: Needed to clone the source code.
# openssl-dev, zlib-dev: Dev libraries for HTTPS and compression support.
RUN apk update && \
    apk add --no-cache build-base git openssl-dev zlib-dev pkgconfig

# Clone the cgit source code and change directory.
WORKDIR /usr/src
RUN git clone https://git.zx2c4.com/cgit
WORKDIR /usr/src/cgit

# Prepare configuration and compile cgit.
# 1. Copy example configuration.
# 2. Create config.mk to explicitly enable ZLIB/SSL and disable Lua/Tcl (optional features).
# 3. Explicitly set the path for the git executable.
RUN cp cgit.conf cgit.conf.example && \
    echo "CGIT_SCRIPT_NAME = cgit.cgi" > config.mk && \
    echo "NO_LUA = 1" >> config.mk && \
    echo "NO_TCL = 1" >> config.mk && \
    echo "USE_ZLIB = 1" >> config.mk && \
    echo "USE_LIBRESSL = 1" >> config.mk && \
    echo "GIT_EXECUTABLE = /usr/bin/git" >> config.mk

# Compile cgit executable (cgit.cgi).
RUN make

# -----------------------------------------------------------------------------
# Stage 2: Final Runtime Stage (Based on the user's original image)
# This stage installs all runtime dependencies and copies the compiled cgit.
# -----------------------------------------------------------------------------
FROM alpine:3.22.2

# 1. Install all runtime dependencies (excluding the pre-built 'cgit' package).
# We add runtime dependencies for cgit (openssl, zlib) manually.
# Using 'set -xe' to exit immediately if any command fails.
RUN set -xe \
    && apk update \
    && apk upgrade \
    && apk add --no-cache --purge -uU \
        # Install gitolite
        gitolite git openssh \
        # install git-daemon
        git-daemon \
        # add nginx and fastcgi runner
        nginx fcgiwrap spawn-fcgi \
        # cgit runtime dependencies
        openssl zlib \
        # python 3 pkg for highlight, about page
        py3-markdown py3-pygments \
        # tarballs support
        lzip xz zstd gzip bzip2 \
    # Create necessary folders for cgit and nginx
    && mkdir -p /run/nginx /usr/share/webapps/cgit /usr/lib/cgit/filters/html-converters \
    # Clean up apk cache to minimize the image size
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# 2. Copy compiled cgit files from the builder stage
# Copy the compiled cgit executable
COPY --from=cgit_builder /usr/src/cgit/cgit.cgi /usr/bin/cgit.cgi
# Copy static resources
COPY --from=cgit_builder /usr/src/cgit/cgit.css /usr/share/webapps/cgit/cgit.css
COPY --from=cgit_builder /usr/src/cgit/cgit.png /usr/share/webapps/cgit/cgit.png
# Copy example configuration
COPY --from=cgit_builder /usr/src/cgit/cgit.conf.example /etc/cgitrc.example

# Volume to store all ssh host key
VOLUME [ "/etc/ssh" ]

# Volume to store Gitolite data, used for Gitolite setup
VOLUME [ "/var/lib/git" ]

EXPOSE 22 80 9418
WORKDIR /var/lib/git

# Copy local files provided by the user
COPY cgit.css /usr/share/webapps/cgit/cgit.css
COPY md2html /usr/lib/cgit/filters/html-converters/md2html
COPY syntax-highlighting.py /usr/lib/cgit/filters/syntax-highlighting.py
COPY auto-default-branch.sh /usr/lib/gitolite/triggers/auto-default-branch
COPY entrypoint.sh /

# Set executable permissions
RUN chmod u+x /usr/lib/cgit/filters/html-converters/md2html
RUN chmod u+x /usr/lib/cgit/filters/syntax-highlighting.py
RUN chmod a+x /usr/lib/gitolite/triggers/auto-default-branch
RUN chmod u+x /entrypoint.sh
RUN chmod u+x /usr/bin/cgit.cgi

ENTRYPOINT ["/entrypoint.sh"]