# ZFSonLinux stable version
zol_version="0.7.6"

# The ZOL source hashes are from zfsonlinux.org
spl_src_hash="648148762969d1ee94290c494c4f022aeacabe0e84cddf65906af608be666f95"
zfs_src_hash="1687f4041a990e35caccc4751aa736e8e55123b81d5f5a35b11916d9e580c23d"

zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="e33adabbe3f2f4866802c9d63c7810c7a42b4df2288d0cdd23376519b15b36e4"
zfs_initcpio_hook_hash="3eb874cf2cbb6c6a0e1c11a98af54f682d6225667af944b43435aeabafa0112f"

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
