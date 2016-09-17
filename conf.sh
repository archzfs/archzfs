# ZFSonLinux stable version
zol_version="0.6.5.8"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="d77f43f7dc38381773e2c34531954c52f3de80361b7bb10c933a7482f89cfe84"
spl_src_hash="2d22117106782222d2b7da88cc657b7b9c44d281b1cc74d60761e52d33ab1155"
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
