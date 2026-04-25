#!/bin/sh

info() { printf >&2 %s\\n "$*" ; }

die()  { info "$*" ; exit 1 ; }

ensure_HEAD() {
   [ "$1" = 'POST_GIT' ] || die "unsupported trigger '$1'"

   cd "$GL_REPO_BASE/$2.git"

   # everything OK if the default in HEAD points to a real branch
   git show-ref --quiet --verify "$(git symbolic-ref HEAD)" && return 0

   # there *might* be a mismatch, so let's find out a real branch
   local head
   head="$(git show-ref --heads | head -1 | sed -e 's/^.* //')"

   # the repo might still be empty
   [ -n "$head" ] || return 0

   # we have a default branch that we can set here
   info "setting HEAD to <$head>"
   git symbolic-ref HEAD "$head" -m "Default HEAD to branch <$head>"
}

set -eu

ensure_HEAD "$@"
