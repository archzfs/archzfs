# ZFSonLinux stable version
zol_version="0.6.5.11"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="136b3061737f1a43f5310919cacbf1b8a0db72b792ef8b1606417aff16dab59d"
spl_src_hash="ebab87a064985f93122ad82721ca54569a5ef20dc3579f84d18075210cf316ac"
zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="aa5706bf08b36209a318762680f3c9fb45b3fc4b8e4ef184c8a5370b2c3000ca"
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
