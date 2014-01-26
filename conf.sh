# Version information
AZB_PKGREL="1"  # The pkgrel of all the archzfs packages

# ZFSonLinux version
AZB_ZOL_VERSION="0.6.2"

# Linux version dependencies
AZB_LINUX_VERSION="3.12.8"
AZB_LINUX_PKGREL="1" # The PKGREL must be increased if this value changes.
AZB_LINUX_VERSION_FULL="$AZB_LINUX_VERSION-$AZB_LINUX_PKGREL"

# Package version number
AZB_PKG_VERSION="${AZB_ZOL_VERSION}_${AZB_LINUX_VERSION}"
AZB_FULL_VERSION="$AZB_PKG_VERSION-$AZB_PKGREL"

# Archiso Configuration
AZB_LINUX_ARCHISO="3.12.6"
AZB_LINUX_ARCHISO_PKGREL="1"
AZB_ARCHISO_FULL_VERSION="${AZB_ZOL_VERSION}_${AZB_LINUX_ARCHISO}-$AZB_LINUX_ARCHISO_PKGREL"

# Notification address
AZB_EMAIL="jeezusjr@gmail.com"

# Repository path and name
AZB_REPO_BASEPATH="/data/pacman/repo"

# SSH login address
AZB_REMOTE_LOGIN="jalvarez@jalvarez.webfactional.com"

# The signing key to use to sign packages
AZB_GPG_SIGN_KEY='0EE7A126'
