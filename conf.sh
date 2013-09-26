# Version information
PKGREL="2"  # The pkgrel of all the archzfs packages

# ZFSonLinux version
ZOL_VERSION="0.6.2"

# Linux version dependencies
LINUX_VERSION="3.11.1"
LINUX_PKGREL="2"
LINUX_VERSION_FULL="$LINUX_VERSION-$LINUX_PKGREL"
LINUX_ARCHISO="3.10.10"

# Package version number
PKG_VERSION="${ZOL_VERSION}_${LINUX_VERSION}"
FULL_VERSION="$PKG_VERSION-$PKGREL"

# Notification address
EMAIL="jeezusjr@gmail.com"

# Chroot path and name
CHROOT_PATH="/opt/chroot"
CHROOT_COPYNAME="azfs"

# Repository path and name
REPO_BASEPATH="/data/pacman/repo"

# SSH login address
REMOTE_LOGIN="jalvarez@jalvarez.webfactional.com"

# The signing key to use to sign packages
GPG_SIGN_KEY='0EE7A126'
