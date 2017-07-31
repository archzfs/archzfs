# ZFSonLinux stable version
zol_version="0.7.0"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="6907524f5ca4149b799fe65cd31b552b0ae90dba5dc20524e1a24fc708d807d2"
spl_src_hash="567f461435f99f862efb1b740ed0876b52a2a539aafad6e5372a84a06a5da4d3"
zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="aa5706bf08b36209a318762680f3c9fb45b3fc4b8e4ef184c8a5370b2c3000ca"
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

# For embedding in the archiso for testing
ssh_public_key_file="/home/demizer/.ssh/id_rsa_demizer_alvaone_2015-04-12.pub"
azfstest_static_ip="192.168.1.100\/24"
azfstest_gateway="192.168.1.1"
