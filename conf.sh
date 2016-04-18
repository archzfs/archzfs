# ZFSonLinux stable version (LTS packages)
AZB_ZOL_VERSION="0.6.5.6"

# Kernel versions for default ZFS packages
AZB_DEF_PKGREL="1"
AZB_DEF_KERNEL_VERSION="4.5-1"

# Kernel version for GIT packages
AZB_DEF_GIT_SPL_COMMIT="5079f5b3"
AZB_DEF_GIT_ZFS_COMMIT="21f21fe8"
AZB_DEF_GIT_PKGREL="1"
AZB_DEF_GIT_KERNEL_VERSION="4.5-1"

# Kernel versions for LTS packages
AZB_LTS_PKGREL="1"
AZB_LTS_KERNEL_VERSION="4.4.7-1"

# Archiso Configuration
AZB_ARCHISO_PKGREL="1"
AZB_KERNEL_ARCHISO_VERSION="4.4.5-1"

# Testing repo Linux version dependencies
# AZB_KERNEL_TEST_VERSION="3.13.8-1"

# Notification address
AZB_EMAIL="jeezusjr@gmail.com"

# Repository path and name
AZB_REPO_BASEPATH="/data/pacman/repo"

# SSH login address (can use ssh config Hosts)
AZB_REMOTE_LOGIN="webfaction"

# The signing key to use to sign packages
AZB_GPG_SIGN_KEY='0EE7A126'

# Package backup directory (for adding packages to demz-repo-archiso)
AZB_PACKAGE_BACKUP_DIR="/data/pacman/repo/archive_archzfs"

AZB_DEF_PKG_LIST="spl-utils spl zfs-utils zfs"
AZB_GIT_PKG_LIST="spl-utils-git spl-git zfs-utils-git zfs-git"
AZB_LTS_PKG_LIST="spl-utils-lts spl-lts zfs-utils-lts zfs-lts"
