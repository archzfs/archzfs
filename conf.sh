# ZFSonLinux stable version
zol_version="0.7.1"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="231b104979ddacfeb1889e1dec175337276e7b3b109d40656089744b5caf3ef6"
spl_src_hash="e6a83dc50bc83a5ce6f20238da16fb941ab6090c419be8af8fc9223210f637fd"
zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="e33adabbe3f2f4866802c9d63c7810c7a42b4df2288d0cdd23376519b15b36e4"
zfs_initcpio_hook_hash="2bb533db561992c861bb9acad64a127f81cf0e4bf39cb4308ac7a73a17db55a7"

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
