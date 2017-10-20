# ZFSonLinux stable version
zol_version="0.7.3"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="cb8fc606835d3f91471e49aca31a6a0a71733b1cbe74fa510e0fe0efa670fe51"
spl_src_hash="cd8b8624163577bdec1d1d214c942c5771f183432a04d35c00fc6e7f12fa836b"

zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="e33adabbe3f2f4866802c9d63c7810c7a42b4df2288d0cdd23376519b15b36e4"
zfs_initcpio_hook_hash="b5f87d1d1d10443d8919125a4c139d5f4c579ca4433b2905ee826bb01defa56a"

# Notification address
email="jeezusjr@gmail.com"

# Repository path and name
repo_name="archzfs"
repo_basepath="/data/pacman/repo"
repo_name_test="archzfs-testing"

# SSH login address (can use ssh config Hosts)
remote_login="webfaction"

# The signing key to use to sign packages
gpg_sign_key='0EE7A126'

chroot_path="/opt/chroot/x86_64/$(whoami)"

# Package backup directory
package_backup_dir="/data/pacman/repo/archive_archzfs"

# Used to run mkaurball and mksrcinfo with lower privledges
makepkg_nonpriv_user="demizer"
