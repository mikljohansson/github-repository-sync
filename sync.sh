#/bin/bash
set -e

GITREPO="$GIT_REPOSITORY_URL"
GITREPODIR="/repository"
ENVDIR="/branches"

# Initial clone
if [ ! -e "$GITREPODIR/.git" ]; then
    git clone "$GITREPO" "$GITREPODIR"
    cd "$GITREPODIR"

    git submodule sync || echo "Failed submodule sync"
    git submodule update --init || echo "Failed submodule update in master"
fi

# Get current branches
echo "Git fetching into $GITREPODIR"
cd $GITREPODIR || exit 1
git fetch -p || exit 1

BRANCHES=$(git branch -r | egrep -v 'HEAD' | awk -F/ '{print $2}')
[[ -z $BRANCHES ]] && echo "Failed git branch listing in $(pwd)" && exit 2

# Initialize new branches not seen before
while read branch; do
  if [[ ! -e "$ENVDIR/$branch" ]]; then
    echo "Creating $ENVDIR/$branch"
    cp -rf $GITREPODIR $ENVDIR/$branch || echo "Failed to copy $GITREPODIR"
    cd $ENVDIR/$branch || exit 4
    git checkout -f --track -b "$branch" "origin/$branch" || echo "Failed git checkout $branch"
    git submodule sync || echo "Failed submodule sync"
    git submodule update --init || echo "Failed submodule update in $ENVDIR/$branch"
  fi
done <<< "$BRANCHES"

# Update existing branches and removing deleted ones
for fdir in $ENVDIR/*; do
  dir="${fdir##*/}"
  DELETE=1

  while read branch; do
    if [[ "$dir" == "$branch" ]]; then
      DELETE=0
      cd $ENVDIR/$branch || exit 5

      # Fetch from fast local master clone instead of github.com
      git fetch --force "$GITREPODIR" "origin/$branch:refs/remotes/origin/$branch" || echo "Failed to git fetch from $GITREPODIR"

      # Check if anything has changed in this branch
      LOCAL=$(git rev-parse @)
      REMOTE=$(git rev-parse @{u})

      if [ "$LOCAL" == "$REMOTE" ]; then
        echo "Branch $branch has not changed"
        continue
      fi

      echo "Branch $branch changed from $LOCAL to $REMOTE"
      git pull --rebase origin "$branch" || echo "Failed to git pull/rebase origin/$branch"
      if [[ $? -ne 0 ]]; then
        echo "ERROR Having issues doing a pull for ${branch} branch"
      fi    

      git submodule sync || echo "Failed submodule sync in $ENVDIR/$branch"
      git submodule update --init || echo "Failed submodule update in $ENVDIR/$branch"
      if [[ $? -ne 0 ]]; then
        git submodule foreach 'rm -rf $path' > /dev/null
        git submodule sync >/dev/null
        git submodule update --init --force >/dev/null
        if [[ $? -ne 0 ]]; then
          echo "ERROR: Having issues updating submodules for ${branch} branch"
        fi  
      fi
    fi
  done <<< "$BRANCHES"

  if [[ "$DELETE" == 1 ]] && [[ "$dir" =~ ^[[:alnum:]].* ]]; then
    echo "Deleting $ENVDIR/$dir";
    rm -rvf $ENVDIR/$dir
  fi
done
