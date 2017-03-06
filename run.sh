#!/bin/sh
GREEN="\x1B[32m"
RED="\x1B[31m"
YELLOW="\x1B[33m"
RESET="\x1B[0m"

log() { printf "%b" "$GREEN$1$RESET\n" }
warn() { printf "%b" "$RED$1$RESET\n" }
error() { printf "%b" "$RED$1$RESET\n" exit 1 }

BRANCH=$(git rev-parse --abbrev-ref HEAD)

# check if remote branch exists
REMOTE=origin
REMOTE_BRANCH=$REMOTE/$BRANCH
git branch -a | grep $REMOTE_BRANCH
if [ $? = 1 ]; then
  REMOTE_BRANCH=$REMOTE/master
fi

COMMITED_FILES=$(git diff --name-only --diff-filter=ACM --name-only $REMOTE_BRANCH..$BRANCH | grep ".jsx\{0,1\}$")

if [[ "$COMMITED_FILES" = "" ]]; then
  log 'No files to lint.'
  exit 0
fi

PASS=true

log 'Linting committed files...\n'

for FILE in $COMMITED_FILES
do
  if [ -f ~/.eslint_d_port ]; then
    # quiet: Report errors only so that the fact that .eslintignore is being used and
    # thus triggers a warning (-.-) doesn't fail the build.
    eslint_d --cache --max-warnings 0 --quiet "$FILE"
  else
    eslint --cache --max-warnings 0 --quiet "$FILE"
  fi

  if [[ "$?" == 0 ]]; then
    log "  ✓ $FILE"
  else
    warn "  ✘ $FILE"
    PASS=false
  fi
done



if [ "$PASS" = false ]; then
  error "\nPush failed: The commits contain files that don't pass eslint."
else
	log 'Running flow...\n'
	flow
fi

exit $?
