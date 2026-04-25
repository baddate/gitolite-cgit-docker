#!/bin/sh

# $1 is repo name
cd "$GL_REPO_BASE/$1.git"

# If there’s already a master branch, use it
git show-ref --verify --quiet "refs/heads/master" && \
  git symbolic-ref HEAD "refs/heads/master" && exit 0

# Otherwise pick whatever branch exists
BRANCH=$(git show-ref --heads | head -n1 | sed 's|.*/||')
[ -n "$BRANCH" ] && \
  git symbolic-ref HEAD "refs/heads/$BRANCH"
