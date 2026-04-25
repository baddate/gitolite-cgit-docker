#!/usr/bin/env sh
set -euo pipefail

# Force security SSH parameters
if [ ! -f /etc/ssh/sshd_config ]; then
  cat > /etc/ssh/sshd_config <<- EOF
# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/bin:/usr/bin:/sbin:/usr/sbin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 30
MaxStartups 10:30:60
AllowUsers git

PubkeyAuthentication yes

# The default is to check both .ssh/authorized_keys and .ssh/authorized_keys2
# but this is overridden so installations will only check .ssh/authorized_keys
AuthorizedKeysFile	.ssh/authorized_keys

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication no
PermitEmptyPasswords no
AuthenticationMethods publickey

# Change to no to disable s/key passwords
#ChallengeResponseAuthentication yes

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
#UsePAM no

AllowAgentForwarding no
# Feel free to re-enable these if your use case requires them.
AllowTcpForwarding no
GatewayPorts no
X11Forwarding no
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
#PrintMotd yes
#PrintLastLog yes
#TCPKeepAlive yes
PermitUserEnvironment no
# gitolite does not require an interactive shell
PermitTTY no
#Compression delayed
ClientAliveInterval 300
ClientAliveCountMax 2
UseDNS no
#PidFile /run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# override default of no subsystems
Subsystem	sftp	/usr/lib/ssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#	X11Forwarding no
#	AllowTcpForwarding no
#	PermitTTY no
#	ForceCommand cvs server

# Algorithms
Ciphers chacha20-poly1305@openssh.com
KexAlgorithms curve25519-sha256
MACs hmac-sha2-512-etm@openssh.com
HostKeyAlgorithms=ssh-ed25519
EOF
fi

# Ensure /var/lib/git is owned by git before gitolite setup runs.
# Docker named volumes are created root:root — fix this on every start (fast).
chown git:git /var/lib/git
chmod 750 /var/lib/git

# -------------------------
# /var/lib/git/.gitolite.rc
# -------------------------
if [ ! -f /var/lib/git/.gitolite.rc ]; then
  cat > /var/lib/git/.gitolite.rc <<- 'EOF'
# configuration variables for gitolite

# This file is in perl syntax.  But you do NOT need to know perl to edit it --
# just mind the commas, use single quotes unless you know what you're doing,
# and make sure the brackets and braces stay matched up!

# (Tip: perl allows a comma after the last item in a list also!)

# HELP for commands can be had by running the command with "-h".

# HELP for all the other FEATURES can be found in the documentation (look for
# "list of non-core programs shipped with gitolite" in the master index) or
# directly in the corresponding source file.

%RC = (

    # ------------------------------------------------------------------

    # default umask gives you perms of '0700'; see the rc file docs for
    # how/why you might change this
    UMASK                           =>  0027,

    # look for "git-config" in the documentation
    GIT_CONFIG_KEYS                 =>  '.*',

    # comment out if you don't need all the extra detail in the logfile
    LOG_EXTRA                       =>  1,
    # logging options
    # 1. leave this section as is for 'normal' gitolite logging (default)
    # 2. uncomment this line to log ONLY to syslog:
    # LOG_DEST                      => 'syslog',
    # 3. uncomment this line to log to syslog and the normal gitolite log:
    # LOG_DEST                      => 'syslog,normal',
    # 4. prefixing "repo-log," to any of the above will **also** log just the
    #    update records to "gl-log" in the bare repo directory:
    # LOG_DEST                      => 'repo-log,normal',
    # LOG_DEST                      => 'repo-log,syslog',
    # LOG_DEST                      => 'repo-log,syslog,normal',
    # syslog 'facility': defaults to 'local0', uncomment if needed.  For example:
    # LOG_FACILITY                  => 'local4',

    # roles.  add more roles (like MANAGER, TESTER, ...) here.
    #   WARNING: if you make changes to this hash, you MUST run 'gitolite
    #   compile' afterward, and possibly also 'gitolite trigger POST_COMPILE'
    ROLES => {
        READERS                     =>  1,
        WRITERS                     =>  1,
    },

    # enable caching (currently only Redis).  PLEASE RTFM BEFORE USING!!!
    # CACHE                         =>  'Redis',

    # ------------------------------------------------------------------

    # rc variables used by various features

    # the 'info' command prints this as additional info, if it is set
        # SITE_INFO                 =>  'Please see http://blahblah/gitolite for more help',

    # the CpuTime feature uses these
        # display user, system, and elapsed times to user after each git operation
        # DISPLAY_CPU_TIME          =>  1,
        # display a warning if total CPU times (u, s, cu, cs) crosses this limit
        # CPU_TIME_WARN_LIMIT       =>  0.1,

    # the Mirroring feature needs this
        # HOSTNAME                  =>  "foo",

    # TTL for redis cache; PLEASE SEE DOCUMENTATION BEFORE UNCOMMENTING!
        # CACHE_TTL                 =>  600,

    # ------------------------------------------------------------------

    # suggested locations for site-local gitolite code (see cust.html)

        # this one is managed directly on the server
        # LOCAL_CODE                =>  "$ENV{HOME}/local",

        # or you can use this, which lets you put everything in a subdirectory
        # called "local" in your gitolite-admin repo.  For a SECURITY WARNING
        # on this, see http://gitolite.com/gitolite/non-core.html#pushcode
        # LOCAL_CODE                =>  "$rc{GL_ADMIN_BASE}/local",

    # ------------------------------------------------------------------

    # List of commands and features to enable

    ENABLE => [

        # COMMANDS

            # These are the commands enabled by default
            'help',
            'desc',
            'info',
            'perms',
            'writable',
            'symbolic-ref',

            # Uncomment or add new commands here.
            'create',
            'fork',
            'mirror',
            'readme',
            'sskm',
            'D',

        # These FEATURES are enabled by default.

            # essential (unless you're using smart-http mode)
            'ssh-authkeys',

            # creates git-config entries from gitolite.conf file entries like 'config foo.bar = baz'
            'git-config',

            # creates git-daemon-export-ok files; if you don't use git-daemon, comment this out
            'daemon',

            # creates projects.list file; if you don't use gitweb, comment this out
            'gitweb',

        # These FEATURES are disabled by default; uncomment to enable.  If you
        # need to add new ones, ask on the mailing list :-)

        # user-visible behaviour

            # prevent wild repos auto-create on fetch/clone
            # 'no-create-on-read',
            # no auto-create at all (don't forget to enable the 'create' command!)
            # 'no-auto-create',

            # access a repo by another (possibly legacy) name
            # 'Alias',

            # give some users direct shell access.  See documentation in
            # sts.html for details on the following two choices.
            # "Shell $ENV{HOME}/.gitolite.shell-users",
            # 'Shell alice bob',

            # set default roles from lines like 'option default.roles-1 = ...', etc.
            # 'set-default-roles',

            # show more detailed messages on deny
            # 'expand-deny-messages',

            # show a message of the day
            # 'Motd',

        # system admin stuff

            # enable mirroring (don't forget to set the HOSTNAME too!)
            # 'Mirroring',

            # allow people to submit pub files with more than one key in them
            # 'ssh-authkeys-split',

            # selective read control hack
            # 'partial-copy',

            # manage local, gitolite-controlled, copies of read-only upstream repos
            # 'upstream',

            # updates 'description' file instead of 'gitweb.description' config item
            # 'cgit',

            # allow repo-specific hooks to be added
            # 'repo-specific-hooks',

        # performance, logging, monitoring...

            # be nice
            # 'renice 10',

            # log CPU times (user, system, cumulative user, cumulative system)
            # 'CpuTime',

        # syntactic_sugar for gitolite.conf and included files

            # allow backslash-escaped continuation lines in gitolite.conf
            # 'continuation-lines',

            # create implicit user groups from directory names in keydir/
            # 'keysubdirs-as-groups',

            # allow simple line-oriented macros
            # 'macros',

        # Kindergarten mode

            # disallow various things that sensible people shouldn't be doing anyway
            # 'Kindergarten',
    ],

    POST_GIT => [
        'auto-default-branch',
    ],
    POST_CREATE => [
        'set-master-branch',
    ],

);

# ------------------------------------------------------------------------------
# per perl rules, this should be the last line in such a file:
1;

# Local variables:
# mode: perl
# End:
# vim: set syn=perl:
EOF
fi

# -------------------------------
# Validate environment variables
# -------------------------------

# Create ssh host key if not present
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
  ssh-keygen -A
fi

# Setup gitolite at volume /var/lib/git
if [ ! -f "/var/lib/git/.ssh/authorized_keys" ]; then
  # Configure gitolite
  echo "$SSH_KEY" > "/tmp/$SSH_KEY_NAME.pub"
  su git -c "gitolite setup -pk \"/tmp/$SSH_KEY_NAME.pub\""
  rm "/tmp/$SSH_KEY_NAME.pub"
fi

if [ ! -d /etc/nginx/http.d ]; then
    install -d -m755 /etc/nginx/http.d || true
fi

# Init container — guard on the persistent volume file, not the tmpfs symlink
if [ ! -f /var/lib/git/cgitrc ]; then
  # Write cgitrc to the persistent git volume (/etc/cgitrc is read-only rootfs).
  # A symlink /etc/cgitrc -> /var/lib/git/cgitrc is created below.
  cat > /var/lib/git/cgitrc <<- EOF
#
# cgit config
#

virtual-root=/

# Use a custom logo
logo=/cgit.png

# Specify the css url
css=/cgit.css

# Enable configuration from external management, for example: gitolite
enable-git-config=1

# Show extra links for each repository on the index page
enable-index-links=1

# Show owner
enable-index-owner=1

# Enable blame page and create links to it from tree page
enable-blame=1

# Sort branches by date
branch-sort=age

# Enable ASCII art commit history graph on the log pages
enable-commit-graph=1

# Allow http transport git clone
enable-http-clone=$ENABLE_HTTP_CLONE

# Show number of affected files per commit on the log pages
enable-log-filecount=1

# Show number of added/removed lines per commit on the log pages
enable-log-linecount=1

# Enable statistics per week, month and quarter
max-stats=quarter

# Cache
cache-about-ttl=15
cache-dynamic-ttl=5
cache-repo-ttl=5
cache-root=/var/cache/cgit
cache-root-ttl=5
cache-scanrc-ttl=15
cache-size=0
cache-snapshot-ttl=5
cache-static-ttl=-1

# Sort items in the repo list case sensitively. Default value: "1"
case-sensitive-sort=1

# Specifies the maximum size of a blob to display HTML for in KBytes. Default value: "0" (limit disabled)
max-blob-size=2048

# Specifies the number of entries to list per page on the repository index page. Default value: "50".
max-repo-count=250


# Specifies the maximum number of repo description characters to display on the repository index page.
# Default value: "80"
max-repodesc-length=80

# Set the default maximum statistics period. Valid values are "week", "month", "quarter" and "year".
# If unspecified, statistics are disabled. Default value: none
max-stats=year

#
# List of common mimetypes
#

mimetype.gif=image/gif
mimetype.htm=text/html
mimetype.html=text/html
mimetype.ico=image/x-icon
mimetype.jpg=image/jpeg
mimetype.jpeg=image/jpeg
mimetype.md=text/markdown
mimetype.mng=video/x-mng
mimetype.ora=image/openraster
mimetype.pam=image/x-portable-arbitrarymap
mimetype.pbm=image/x-portable-bitmap
mimetype.pdf=application/pdf
mimetype.pgm=image/x-portable-graymap
mimetype.png=image/png
mimetype.pnm=image/x-portable-anymap
mimetype.ppm=image/x-portable-pixmap
mimetype.svg=image/svg+xml
mimetype.svgz=image/svg+xml
mimetype.tga=image/x-tga
mimetype.tif=image/tiff
mimetype.tiff=image/tiff
mimetype.webp=image/webp
mimetype.xbm=image/x-xbitmap
mimetype.xcf=image/x-xcf
mimetype.xpm=image/x-xpixmap

# Enable syntax highlighting
source-filter=/usr/lib/cgit/filters/syntax-highlighting.py

# Include some more info about example.com on the index page
root-readme=/var/www/htdocs/cgit/root-readme.md

#
# List of common readmes
#
readme=:README.md
readme=:readme.md
readme=:README.mkd
readme=:readme.mkd
readme=:README.rst
readme=:readme.rst
readme=:README.html
readme=:readme.html
readme=:README.htm
readme=:readme.htm
readme=:README.txt
readme=:readme.txt
readme=:README
readme=:readme
readme=:INSTALL.md
readme=:install.md
readme=:INSTALL.mkd
readme=:install.mkd
readme=:INSTALL.rst
readme=:install.rst
readme=:INSTALL.html
readme=:install.html
readme=:INSTALL.htm
readme=:install.htm
readme=:INSTALL.txt
readme=:install.txt
readme=:INSTALL
readme=:install

snapshots=$CGIT_SNAPSHOT

# Direct cgit to repository location managed by gitolite
remove-suffix=0
project-list=/var/lib/git/projects.list
section-from-path=1
scan-path=/var/lib/git/repositories
EOF

  # Append clone-prefix
  if [ -n "$CGIT_CLONE_PREFIX" ]; then
      echo "# Specify some default clone prefixes" >> /var/lib/git/cgitrc
      echo "clone-prefix=$CGIT_CLONE_PREFIX" >> /var/lib/git/cgitrc
  fi

  if [ -n "$CGIT_ROOT_TITLE" ]; then
      echo "# Set the title and heading of the repository index page" >> /var/lib/git/cgitrc
      echo "root-title=$CGIT_ROOT_TITLE" >> /var/lib/git/cgitrc
  fi

  if [ -n "$CGIT_DESC" ]; then
      echo "# Set description repository" >> /var/lib/git/cgitrc
      echo "root-desc=$CGIT_DESC" >> /var/lib/git/cgitrc
  fi

  # Using highlight syntax
  #sed -i.bak \
  #  -e "s#exec highlight --force -f -I -X -S #\#&#g" \
  #  -e "s#\#exec highlight --force -f -I -O xhtml#exec highlight --force --inline-css -f -I -O xhtml#g" \
  #  /usr/lib/cgit/filters/syntax-highlighting.sh

  # (nginx config is generated unconditionally below, outside this if-block)

fi

# -------------------------------------------------------
# Nginx configuration — regenerated every start (tmpfs is ephemeral)
# -------------------------------------------------------
mkdir -p /run/nginx-conf
cat > /run/nginx-conf/cgit.conf <<- EOF
server {
    listen 80 default_server;
    server_name localhost;

    # Use tmpfs-backed paths so nginx works under read-only rootfs
    client_body_temp_path /tmp/nginx/client_body 1 2;
    fastcgi_temp_path /tmp/nginx/fastcgi 1 2;
    proxy_temp_path /tmp/nginx/proxy 1 2;
    uwsgi_temp_path /tmp/nginx/uwsgi 1 2;
    scgi_temp_path /tmp/nginx/scgi 1 2;

    # ------------------------------
    # Logs (change to real paths if needed)
    # ------------------------------
    access_log /var/log/nginx/cgit.access.log;
    error_log  /var/log/nginx/cgit.error.log;

    # ------------------------------
    # Root directory, contains cgit.cgi and static assets
    # ------------------------------
    root /var/www/htdocs/cgit;

    # ------------------------------
    # Serve static files (CSS/JS/images/robots.txt) directly
    # ------------------------------
    location /cgit.css  { try_files \$uri =404; }
    location /cgit.js   { try_files \$uri =404; }
    location /cgit.png  { try_files \$uri =404; }
    location /favicon.ico { try_files \$uri =404; }
    location /robots.txt { try_files \$uri =404; }

    # ------------------------------
    # CGI execution for dynamic content
    # ------------------------------
    location / {
        try_files \$uri @cgit;
    }

    location @cgit {
        include fastcgi_params;

        # Path to the actual cgit.cgi script
        fastcgi_param SCRIPT_FILENAME \$document_root/cgit.cgi;

        # Preserve PATH_INFO and QUERY_STRING
        fastcgi_param PATH_INFO       \$uri;
        fastcgi_param QUERY_STRING    \$args;
        fastcgi_param QUERY_INFO      \$uri;
        fastcgi_param HTTP_HOST       \$server_name;

        fastcgi_pass unix:/run/fcgiwrap/fcgiwrap.socket;
    }

    # ------------------------------
    # Enable gzip compression for CSS/JS/HTML/etc
    # ------------------------------
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_buffers 16 8k;
    gzip_comp_level 2;
    gzip_types text/css application/javascript image/svg+xml
           font/truetype font/opentype application/vnd.ms-fontobject;

    # ------------------------------
    # Optimize timeouts and sendfile
    # ------------------------------
    client_body_timeout       30s;
    client_header_timeout     10s;
    send_timeout              10s;
    keepalive_timeout         10s;
    reset_timedout_connection on;
    proxy_ignore_client_abort on;

    tcp_nopush on;
    tcp_nodelay on;
    sendfile on;
    sendfile_max_chunk 1M;
    aio threads;
}
EOF
# -------------------------------------------------------
# Runtime symlinks (created every start, idempotent)
# -------------------------------------------------------
# /etc/cgitrc is a symlink baked into the image → /var/lib/git/cgitrc (no action needed)

# /etc/nginx/http.d is mounted as tmpfs (empty on each start).
# Copy our generated config from /run/nginx-conf into the tmpfs http.d.
# Also suppress the nginx "user" directive warning by writing a fixed nginx.conf to tmpfs.
if [ -f /run/nginx-conf/cgit.conf ]; then
  cp /run/nginx-conf/cgit.conf /etc/nginx/http.d/cgit.conf
fi

# Start sshd as detach, log to stderr (-e)
/usr/sbin/sshd -e

# Create runtime directories (needed for tmpfs/read-only rootfs)
# Use mkdir+chmod instead of install to avoid permission issues under no-new-privileges
mkdir -p /run/fcgiwrap && chown fcgiwrap:nginx /run/fcgiwrap && chmod 0750 /run/fcgiwrap
mkdir -p /run/nginx    && chown nginx:nginx /run/nginx         && chmod 0755 /run/nginx
mkdir -p /var/log/nginx && chown nginx:nginx /var/log/nginx    && chmod 0755 /var/log/nginx
mkdir -p /tmp/nginx    && chown nginx:nginx /tmp/nginx         && chmod 0755 /tmp/nginx
mkdir -p /var/lib/nginx/logs && chown nginx:nginx /var/lib/nginx && chmod 0755 /var/lib/nginx

spawn-fcgi -s /run/fcgiwrap/fcgiwrap.socket -u fcgiwrap -g git -U fcgiwrap -G nginx -M 0660 -f /usr/bin/fcgiwrap &

# fix permissions gitolite
stamp_dir=/var/lib/git/.gitolite
stamp_file="$stamp_dir/.permissions-fixed"
if [ "${FORCE_CHOWN:-}" = "1" ] || [ ! -f "$stamp_file" ]; then
  chown git:git /var/lib/git
  chown git:git -R /var/lib/git
  mkdir -p "$stamp_dir"
  chown git:git "$stamp_dir"
  touch "$stamp_file"
  chown git:git "$stamp_file"
fi
chmod 750 /var/lib/git
chown git:git /var/lib/git/.gitolite.rc
chmod 640 /var/lib/git/.gitolite.rc

if [ -d /var/lib/git/.ssh ]; then
  chown -R git:git /var/lib/git/.ssh
  chmod 700 /var/lib/git/.ssh
  if [ -f /var/lib/git/.ssh/authorized_keys ]; then
    chmod 600 /var/lib/git/.ssh/authorized_keys
  fi
fi

# Start git-daemon
(umask 0027; git daemon --detach --syslog --reuseaddr --base-path=/var/lib/git/repositories --listen=0.0.0.0 --user=git --group=git --enable=upload-pack --disable=receive-pack --disable=upload-archive --informative-errors --verbose)

# Drop privileges to cgit user for the foreground nginx process
exec su-exec nginx nginx -g "daemon off;"