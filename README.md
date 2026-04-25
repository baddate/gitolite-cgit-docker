# gitolite-cgit-docker

A self-hosted Git stack running on Alpine Linux, split into two focused containers:

- **gitolite** — SSH-based Git repository management and access control
- **cgit** — Fast, lightweight web UI for browsing repositories (dark mode, Catppuccin theme)

## Images

Both images are published to GitHub Container Registry:

```
ghcr.io/baddate/gitolite-cgit-docker-gitolite:latest
ghcr.io/baddate/gitolite-cgit-docker-cgit:latest
```

---

## Quick start with Docker Compose

### 1. Clone the repository

```console
git clone https://github.com/baddate/gitolite-cgit-docker.git
cd gitolite-cgit-docker
```

### 2. Configure environment

Copy the example env file and fill in your values:

```console
cp .env.example .env
```

The `.env` file:

```ini
#
# Gitolite options
#
SSH_KEY=<your public key content>       # e.g. $(cat ~/.ssh/id_ed25519.pub)
SSH_KEY_NAME=admin                      # gitolite admin username

#
# Cgit options
#
CGIT_ROOT_TITLE=Git Repository Browser
CGIT_DESC=A fast web interface for the git dscm
CGIT_CLONE_PREFIX=https://git.example.com ssh://git@git.example.com

CGIT_SNAPSHOT=tar.gz tar.bz2 tar.xz
ENABLE_HTTP_CLONE=1
```

### 3. Start the stack

```console
docker compose up -d
```

The `docker-compose.yml` ships ready to use:

```yaml
services:
  gitolite:
    image: ghcr.io/baddate/gitolite-cgit-docker-gitolite:latest
    container_name: gitolite
    restart: unless-stopped
    env_file: .env
    ports:
      - "2222:22" # SSH — git clone / push
    volumes:
      - git-data:/var/lib/git # repositories + gitolite home
      - ssh-data:/etc/ssh # persistent SSH host keys
    networks:
      - git-net

  cgit:
    image: ghcr.io/baddate/gitolite-cgit-docker-cgit:latest
    container_name: cgit
    restart: unless-stopped
    ports:
      - "8080:80" # cgit web UI
    volumes:
      - git-data:/var/lib/git:ro # read-only — cgit never writes repos
    depends_on:
      - gitolite
    networks:
      - git-net

volumes:
  git-data:
  ssh-data:

networks:
  git-net:
    driver: bridge
```

Once running:

- Web UI: `http://<host>:8080`
- SSH: `ssh git@<host> -p 2222`

---

## Environment variables

### gitolite container

| Variable       | Required | Description                                                                             |
| -------------- | -------- | --------------------------------------------------------------------------------------- |
| `SSH_KEY`      | ✅       | Public key of the initial gitolite admin (e.g. contents of `~/.ssh/id_ed25519.pub`)     |
| `SSH_KEY_NAME` | ✅       | Username for the gitolite admin account                                                 |
| `FORCE_CHOWN`  | —        | Set to `1` to force-fix volume ownership on every start (useful after volume migration) |

### cgit container

| Variable            | Required | Description                                                                                                      |
| ------------------- | -------- | ---------------------------------------------------------------------------------------------------------------- |
| `ENABLE_HTTP_CLONE` | —        | Enable dumb-HTTP clone via cgit (`1` = enabled, default `1`)                                                     |
| `CGIT_CLONE_PREFIX` | —        | Space-separated clone URL prefixes shown in the web UI, e.g. `https://git.example.com ssh://git@git.example.com` |
| `CGIT_ROOT_TITLE`   | —        | Page heading on the repository index. Default: `Git Repository Browser`                                          |
| `CGIT_DESC`         | —        | Subtitle shown below the heading                                                                                 |
| `CGIT_SNAPSHOT`     | —        | Enabled snapshot formats, e.g. `tar.gz tar.bz2 tar.xz`                                                           |

> **Note:** cgit configuration is generated once into the shared volume at
> `/var/lib/git/cgitrc`. Edit that file directly for any settings not covered
> by the environment variables above. The file is not overwritten on restart.

---

## Exposed ports

| Container | Port | Purpose                                    |
| --------- | ---- | ------------------------------------------ |
| gitolite  | `22` | SSH (git clone / push / gitolite commands) |
| cgit      | `80` | cgit web UI served by nginx                |

The `docker-compose.yml` maps these to `2222` and `8080` on the host by default.
Adjust the left-hand side of the `ports:` mapping to suit your setup.

---

## Volumes

| Volume     | Container | Mode | Contents                                                           |
| ---------- | --------- | ---- | ------------------------------------------------------------------ |
| `git-data` | gitolite  | `rw` | Repositories, gitolite-admin, `.gitolite.rc`, SSH authorized keys  |
| `git-data` | cgit      | `ro` | Same volume, read-only — cgit browses repos but never writes       |
| `ssh-data` | gitolite  | `rw` | SSH host keys (`ssh_host_ed25519_key`) — persisted across restarts |

---

## Cloning repositories

### SSH (read/write)

Authentication is managed by gitolite via `~/.ssh/authorized_keys` inside the volume.

```console
git clone ssh://git@<host>:<port>/<repo>
# default port 2222 when using the provided docker-compose.yml
git clone ssh://git@<host>:2222/myrepo
```

### HTTP (read-only)

HTTP clone is enabled by default (`ENABLE_HTTP_CLONE=1`). Push over HTTP is not supported.

```console
git clone http://<host>:8080/myrepo
```

---

## Customising cgit

The cgit configuration lives at `/var/lib/git/cgitrc` inside the shared volume.
It is created from the built-in template on the first start and **never overwritten** on subsequent restarts, so edits persist.

To inspect or edit it directly:

```console
# Copy out of the volume
docker cp gitolite:/var/lib/git/cgitrc ./cgitrc

# Edit, then copy back
docker cp ./cgitrc gitolite:/var/lib/git/cgitrc
```

Or mount a custom file at start time:

```yaml
volumes:
  - git-data:/var/lib/git
  - ./cgitrc:/var/lib/git/cgitrc # override generated config
```

---

## Gitolite administration

Gitolite is managed through the `gitolite-admin` repository. Clone it with your admin key:

```console
git clone ssh://git@<host>:2222/gitolite-admin
```

### Example `gitolite-admin/conf/gitolite.conf`

```conf
#-----------
#  Groups
#-----------
@admins  = alice
@devs    = bob carol

#-----------
#  Repositories
#-----------
repo gitolite-admin
    RW+ = @admins

repo myproject
    RW+ = @admins
    RW  = @devs
    R   = cgit daemon         # allow cgit and anonymous git-daemon read
    desc = "My project"
    config gitweb.owner = alice

# Personal repos (any member can create their own)
repo CREATOR/[a-zA-Z0-9].*
    C   = @admins @devs
    RW+ = CREATOR
    R   = @all
    config gitweb.owner = %GL_CREATOR
```

### Set default branch for a repository

```console
ssh git@<host> -p 2222 symbolic-ref <repo> HEAD refs/heads/main
```

### Delete a remote branch

```console
git push origin :branch-name
```

---

## Building locally

```console
# gitolite image
docker build -t gitolite-cgit-docker-gitolite ./gitolite

# cgit image
docker build -t gitolite-cgit-docker-cgit ./cgit
```

Multi-arch builds (amd64 + arm64) are handled by the GitHub Actions workflows in
`.github/workflows/`.

---

## Theme

The cgit web UI uses the [Catppuccin](https://github.com/catppuccin/catppuccin) colour scheme:

- **Dark mode** — Catppuccin Macchiato
- **Light mode** — Catppuccin Latte (auto-switched via `prefers-color-scheme`)

Syntax highlighting uses Pygments with the same palette.
