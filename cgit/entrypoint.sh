#!/usr/bin/env sh

set -euo pipefail

# ── Runtime directory setup ───────────────────────────────────────────────────
# All mkdir/chown/chmod in one place. Runs as root (container starts as root).
# Permissions rationale:
#   /run/fcgiwrap  — fcgiwrap Unix socket dir; nginx reads socket (g+rx via nginx group)
#   /run/nginx     — nginx pid/lock files; owned by nginx
#   /tmp/nginx     — nginx temp files; container has read-only rootfs, needs tmpfs
#   /run/cgit-cache — cgit page cache; fcgiwrap writes, nginx has no need to write
setup_runtime_dirs() {
    mkdir -p /run/fcgiwrap   && chown fcgiwrap:nginx  /run/fcgiwrap   && chmod 0750 /run/fcgiwrap
    mkdir -p /run/nginx      && chown nginx:nginx     /run/nginx      && chmod 0755 /run/nginx
    mkdir -p /tmp/nginx      && chown nginx:nginx     /tmp/nginx      && chmod 0700 /tmp/nginx
    mkdir -p /run/cgit-cache && chown fcgiwrap:nginx  /run/cgit-cache && chmod 0750 /run/cgit-cache
}
setup_runtime_dirs

# ── cgitrc ────────────────────────────────────────────────────────────────────
# Generated at runtime into /run (tmpfs) so the image stays read-only.
# Owned by fcgiwrap:nginx, mode 0640: fcgiwrap reads it, nginx has no need.
CONFIG=/run/cgitrc
mkdir -p "$(dirname "$CONFIG")"
cp /usr/local/share/cgitrc.template "$CONFIG"
chown fcgiwrap:nginx "$CONFIG"
chmod 0640 "$CONFIG"

# ── Dynamic Runtime Config Injection (with logging) ──────────────────────────

echo "Initializing cgitrc with environment variables..."

# 使用 env 获取变量，while read 处理流
env | grep '^CGIT_' | while read -r line; do
    # 提取变量名
    var_name=${line%%=*}

    # 获取变量值 (POSIX eval 方式)
    eval var_value="\$$var_name"

    # 如果值为空，打印跳过提示并继续
    if [ -z "$var_value" ]; then
        echo "  [SKIP] $var_name is empty, ignoring."
        continue
    fi

    # 转换逻辑：CGIT_ROOT_TITLE -> root-title
    config_key=$(echo "${var_name#CGIT_}" | tr '[:upper:]' '[:lower:]' | tr '_' '-')

    # 执行替换并加入成功提示
    # 注意：这里使用 printf 格式化输出，看起来更整齐
    if sed -i "s|^${config_key}=.*|${config_key}=${var_value}|" "$CONFIG"; then
        printf "  [APPLIED] %-25s -> %s\n" "$var_name" "$config_key"
    else
        echo "  [ERROR] Failed to update $config_key"
    fi
done

echo "Configuration injection complete."

# ── fcgiwrap ──────────────────────────────────────────────────────────────────
spawn-fcgi \
    -s /run/fcgiwrap/fcgiwrap.socket \
    -u fcgiwrap -g nginx -M 0660 \
    -f /usr/bin/fcgiwrap

# Wait for socket to be ready before starting nginx.
# Avoids 502 on the first few requests after container start.
_timeout=50
while [ ! -S /run/fcgiwrap/fcgiwrap.socket ]; do
    if [ "$_timeout" -le 0 ]; then
        echo "ERROR: fcgiwrap socket not ready after 5s" >&2
        exit 1
    fi
    sleep 0.1
    _timeout=$((_timeout - 1))
done

# ── nginx ─────────────────────────────────────────────────────────────────────
exec nginx -g "daemon off;"