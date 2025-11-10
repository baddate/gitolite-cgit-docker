# Build stage for compiling cgit from source
FROM alpine:3.22.2 AS builder
LABEL stage=cgit_builder

# 1. 安装构建工具和 cgit 所需的依赖库的开发版本 (*-dev)
# build-base: 包含 gcc, make, libc-dev 等基础构建工具
# openssl-dev / libressl-dev: 编译 HTTPS 支持所需的库
# zlib-dev: 编译压缩支持所需的库
# git: 用于克隆源代码，并在 make 编译时可能需要
# pkgconfig: 有些系统需要它来定位头文件和库（虽然 build-base 可能包含，但加上更保险）
RUN apk add --no-cache \
    build-base \
    git \
    openssl-dev \
    zlib-dev \
    pkgconfig

# 2. 克隆 cgit 源代码
# ... (其余步骤与之前相同，确保使用 config.mk 禁用不需要的特性)
WORKDIR /usr/src
RUN git clone https://git.zx2c4.com/cgit
WORKDIR /usr/src/cgit

# 3. 准备配置文件和编译
# 保持简洁，禁用可选依赖（Lua, Tcl）
RUN cp cgit.conf /etc/cgitrc.example && \
    echo "CGIT_SCRIPT_NAME = cgit.cgi" > config.mk && \
    echo "NO_LUA = 1" >> config.mk && \
    echo "NO_TCL = 1" >> config.mk && \
    echo "USE_ZLIB = 1" >> config.mk && \
    # 使用 Alpine 默认的 SSL 库 (通常是 OpenSSL 或 Libressl)
    echo "USE_LIBRESSL = 1" >> config.mk && \
    echo "GIT_EXECUTABLE = /usr/bin/git" >> config.mk

# 4. 编译 cgit
RUN make

# Runtime stage - final image
FROM alpine:3.22.2
LABEL ORIGINAL_MAINTAINER="heckyel@riseup.net"
LABEL MAINTAINER="me@smj.im"

# Install runtime packages (no build tools)
RUN set -xe \
  && apk update \
  && apk upgrade \
  && apk add --no-cache \
    # cgit
    git openssl zlib
    # Install gitolite
    gitolite git openssh \
    # install git-daemon
    git-daemon \
    # add nginx and other runtime components
    nginx fcgiwrap spawn-fcgi \
    # python 3 pkg for highlight, about page
    py3-markdown py3-pygments \
    # tarballs support
    lzip xz zstd gzip bzip2 \
    # cgit runtime dependencies (only libraries, not build tools)
    libxml2 libxslt lua openssl xz-libs zstd bzip2 \
  # Create nginx folder
  && mkdir -p /run/nginx \
  # Clean up
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

# Copy cgit from builder stage
COPY --from=builder /usr/src/cgit/cgit.cgi /var/www/cgit/cgit.cgi
# 复制 cgit 静态资源 (CSS, Logo)
COPY --from=builder /usr/src/cgit/cgit.css /usr/share/webapps/cgit/cgit.css
COPY --from=builder /usr/src/cgit/cgit.png /usr/share/webapps/cgit/cgit.png
# 复制配置示例
COPY --from=builder /etc/cgitrc.example /etc/cgit/cgitrc.example

# Volume to store all ssh host key
VOLUME [ "/etc/ssh" ]

# Volume to store Gitolite data, used for Gitolite setup
VOLUME [ "/var/lib/git" ]

EXPOSE 22 80 9418
WORKDIR /var/lib/git

# Copy configuration and scripts
COPY cgit.css /usr/share/webapps/cgit/cgit.css
COPY md2html /usr/lib/cgit/filters/html-converters/md2html
COPY syntax-highlighting.py /usr/lib/cgit/filters/syntax-highlighting.py
COPY auto-default-branch.sh /usr/lib/gitolite/triggers/auto-default-branch
COPY entrypoint.sh /

# Set permissions
RUN chmod u+x /usr/lib/cgit/filters/html-converters/md2html \
  && chmod u+x /usr/lib/cgit/filters/syntax-highlighting.py \
  && chmod a+x /usr/lib/gitolite/triggers/auto-default-branch \
  && chmod u+x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
