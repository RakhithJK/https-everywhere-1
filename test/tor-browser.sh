#!/bin/bash -ex
# Just run the Tor Browser with HTTPS Everywhere

# Get to the repo root directory, even when we're symlinked as a hook.

if [ -n "$GIT_DIR" ]
then
    # $GIT_DIR is set, so we're running as a hook.
    cd $GIT_DIR
else
    # Git command exists? Cool, let's CD to the right place.
    git rev-parse && cd "$(git rev-parse --show-toplevel)"
fi


source utils/mktemp.sh

die() {
  echo "$@"
  exit 1
}

# Unzip the Tor Browser archive to a temporary directory
if [ ! -f "$1" ] && [ "`echo $1 | tail -c 8 | head -c 7`" != ".tar.xz" ]; then
  die "File provided is not a valid Tor Browser archive."
fi

PROFILE_DIRECTORY="$(mktemp -d)"
trap 'rm -r "$PROFILE_DIRECTORY"' EXIT
tar -Jxvf $1 -C $PROFILE_DIRECTORY > /dev/null
HTTPSE_INSTALL_DIRECTORY=$PROFILE_DIRECTORY/tor-browser_en-US/Browser/TorBrowser/Data/Browser/profile.default/extensions/https-everywhere-eff@eff.org
# Remove the prebundled HTTPSE
rm -rf $HTTPSE_INSTALL_DIRECTORY

# Build the XPI to run all the validations in makexpi.sh, and to ensure that
# we test what is actually getting built.
./makexpi.sh
XPI_NAME="`ls -tr pkg/*-eff.xpi | tail -1`"

# Install into our fresh Tor Browser
unzip -qd $HTTPSE_INSTALL_DIRECTORY $XPI_NAME

if [ ! -d "$HTTPSE_INSTALL_DIRECTORY" ]; then
  die "Tor Browser does not have HTTPS Everywhere installed"
fi

echo "running tor browser"
$PROFILE_DIRECTORY/tor-browser_en-US/Browser/start-tor-browser ${@:2}

shasum=$(openssl sha -sha256 "$XPI_NAME")
echo -e "Git commit `git rev-parse HEAD`\n$shasum"
