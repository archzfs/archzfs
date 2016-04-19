# ZFSonLinux stable version (LTS packages)
AZB_ZOL_VERSION="0.6.5.6"

# The ZOL source hashes are from zfsonlinux.org
AZB_ZFS_SRC_HASH="c349d46d86b4f61cd53a0891acad916cfc3f0d6754127db7f60a0bd98185aeff"
AZB_SPL_SRC_HASH="167595fe76eb5497c3a1ffe396b6300155d0cbe46d06824a710099ca1ae1b8bd"
AZB_SPL_HOSTID_HASH="ad95131bc0b799c0b1af477fb14fcf26a6a9f76079e48bf090acb7e8367bfd0e"
AZB_ZFS_BASH_COMPLETION_HASH="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
AZB_ZFS_INITCPIO_INSTALL_HASH="1e20071fa61a33874505dae0f2d71bb560f43e7faaea735cbde770ea10c133df"
AZB_ZFS_INITCPIO_HOOK_HASH="438a1399d1df5ef20eff37b4d775595fae9943d0c5c105c7bc286b2babcd759e"

# Kernel versions for default ZFS packages
AZB_STD_PKGREL="1"
AZB_STD_KERNEL_VERSION="4.5-1"

# Kernel version for GIT packages
AZB_GIT_SPL_COMMIT="5079f5b3"
AZB_GIT_ZFS_COMMIT="21f21fe8"
AZB_GIT_PKGREL="1"
AZB_GIT_KERNEL_VERSION="4.5-1"

# Kernel versions for LTS packages
AZB_LTS_PKGREL="1"
AZB_LTS_KERNEL_VERSION="4.4.7-1"

# Archiso Configuration
AZB_ARCHISO_PKGREL="1"
AZB_ARCHISO_KERNEL_VERSION="4.4.5"

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

AZB_CHROOT_PATH="/opt/chroot/x86_64/$(whoami)"

# Package backup directory (for adding packages to demz-repo-archiso)
AZB_PACKAGE_BACKUP_DIR="/data/pacman/repo/archive_archzfs"

AZB_STD_PKG_LIST="spl-utils spl zfs-utils zfs"
AZB_GIT_PKG_LIST="spl-utils-git spl-git zfs-utils-git zfs-git"
AZB_LTS_PKG_LIST="spl-utils-lts spl-lts zfs-utils-lts zfs-lts"
