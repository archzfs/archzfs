# ZFSonLinux stable version
zol_version="0.6.5.9"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="b724b57dbddae59246fdc15f88f1224061c712945bb36412a2087e0c7760d77f"
spl_src_hash="d9ccd24786bb5a8616748a93a3c0b1270aa891175e2f5d726195b416f5c03b9c"
zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="17114052aa20c528f022f7f1349971aa28810e2ed2c97871226b5679a91f7e77"
zfs_initcpio_hook_hash="90d50df503464e8d76770488dbd491cb633ee27984d4d3a31b03f1a4e7492038"

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
