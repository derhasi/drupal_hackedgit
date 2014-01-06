## CONSTANTS ########################
DRUPALROOT="../www";
GIT_TEMP_BASE_DIRECTORY="/tmp/hacked"
#####################################

# Stop on first error
set -e;

## FUNCTIONS ########################

# Get absolute path for given argument.
function dhAbsolutePath () {
  # Stop on first error
  set -e;

  # The first argument passed is the path to get the absolute path from.
  SEARCHDIR=${1};

  # Remember the path we come from.
  CURDIR=$(pwd);

  cd "$SEARCHDIR";
  RETURNVAL=$(pwd);

  # Go back to path we came from.
  cd "$CURDIR";

  echo "$RETURNVAL";
}
#####################################

# @todo check is a machine name
PROJECT=${1}
echo "Project: $PROJECT";

# Provide absolute paths for drupal root and git temp directory.
DRUPALROOT=$(dhAbsolutePath $DRUPALROOT);
GIT_TEMP_BASE_DIRECTORY=$(dhAbsolutePath $GIT_TEMP_BASE_DIRECTORY);

# Get the path for the project to compare.
PROJECTPATH="$DRUPALROOT/"$(drush --root=$DRUPALROOT pm-info "$PROJECT" --fields=path --format=list)
PROJECTPATH=$(dhAbsolutePath $PROJECTPATH);
echo "Path: $PROJECTPATH";

# We build the branch from the version info.
VERSION=$(drush --root=../www pm-info "$PROJECT" --fields=version --format=list)
# We suppose versions do not get bigger than "9" for the moment, so we simply
# can take the first 5 characters for the branch name (plus ".x").
BRANCH=${VERSION:0:5}".x"
echo "Branch: $BRANCH";

# Get the project time via php, as long as pm-info does not support datestamp.
# PROJECTTIME=1324599481
PROJECTTIME=$(drush --root="../www" php-eval "print system_rebuild_module_data()['$PROJECT']->info['datestamp'];");
echo "Project time: $PROJECTTIME";

# Build and create the path to clone to.
PROJECTTEMP="$PROJECT""_"$(date +%s)
GIT_PROJECT_DIR="$GIT_TEMP_BASE_DIRECTORY/$PROJECTTEMP";

mkdir -p "$GIT_PROJECT_DIR";
echo "Git destination: $GIT_PROJECT_DIR";

# Check out the project from git.
git clone --branch "$BRANCH" "http://git.drupal.org/project/$PROJECT.git" "$GIT_PROJECT_DIR"
cd "$GIT_PROJECT_DIR"

# Get the latest commit from
LASTHASH=$(git rev-list -n 1 --before="$PROJECTTIME" $BRANCH)

echo "LAST HASH: $LASTHASH";

# Get code for the given hash.
echo "Checking out $LASTHASH";
git checkout --detach "$LASTHASH" --quiet

# Perform diff.
DIFFPATH="$PROJECTPATH/hacked-$PROJECTTEMP.diff";

# Diff exits the whole script for some unknown reason, so we have to switch off
# stopping on error.
set +e;
diff -r --exclude=".git" "$GIT_PROJECT_DIR" "$PROJECTPATH" -u > $DIFFPATH;
set -e;

echo "Created diff at '$DIFFPATH':";
echo "========================================================================";

cat $DIFFPATH;
