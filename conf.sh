# ZFSonLinux stable version
zol_version="0.6.5.6"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="c349d46d86b4f61cd53a0891acad916cfc3f0d6754127db7f60a0bd98185aeff"
spl_src_hash="167595fe76eb5497c3a1ffe396b6300155d0cbe46d06824a710099ca1ae1b8bd"
spl_hostid_hash="ad95131bc0b799c0b1af477fb14fcf26a6a9f76079e48bf090acb7e8367bfd0e"
zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="1e20071fa61a33874505dae0f2d71bb560f43e7faaea735cbde770ea10c133df"
zfs_initcpio_hook_hash="67a96169d36853d8f18ee5a2443ecfcd2461a20f9109f4b281bee3945d83518a"

# Notification address
email="jeezusjr@gmail.com"

# Repository path and name
repo_basepath="/data/pacman/repo"

# SSH login address (can use ssh config Hosts)
remote_login="webfaction"

# The signing key to use to sign packages
gpg_sign_key='0EE7A126'

chroot_path="/opt/chroot/x86_64/$(whoami)"

# Package backup directory (for adding packages to demz-repo-archiso)
package_backup_dir="/data/pacman/repo/archive_archzfs"
