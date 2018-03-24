# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="0.7.7"

# The ZOL source hashes are from zfsonlinux.org
spl_src_hash="9e98af3daaf1a6605b34f8b709a60cfc52dbf2bedcfc01d919d1f77c695247de"
zfs_src_hash="db8ca69dc1d257175421a86bc81c861b2b24cc48db0832c954d9553fe50d0bb9"

zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="e33adabbe3f2f4866802c9d63c7810c7a42b4df2288d0cdd23376519b15b36e4"
zfs_initcpio_hook_hash="3eb874cf2cbb6c6a0e1c11a98af54f682d6225667af944b43435aeabafa0112f"

# Notification address
email="jeezusjr@gmail.com"

# Repository path and name
repo_name="archzfs"
repo_basepath="/repo"
repo_name_test="archzfs-testing"

# SSH login address (can use ssh config Hosts)
remote_login="webfaction"

# The signing key to use to sign packages
gpg_sign_key='0EE7A126'

chroot_path="/repo/chroot/x86_64/$(whoami)"

# Package backup directory
package_backup_dir="/repo/archive_archzfs"

# Used to run mkaurball and mksrcinfo with lower privledges
makepkg_nonpriv_user="demizer"
