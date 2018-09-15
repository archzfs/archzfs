# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="0.7.11"

# The ZOL source hashes are from zfsonlinux.org
spl_src_hash="d6ddd225e7f464007c960f10134c8a48fb0de525f75ad05d5ddf36685b1ced67"
zfs_src_hash="4dff9ecce6e02061242d9435febe88c1250de83b96d392b712bccf31c459517a"

zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="6e5e905a322d0426acdcbc05c5651ec78ee7b874b96d3c429c80f68b061170c5"
zfs_initcpio_hook_hash="ae1cda85de0ad8b9ec8158a66d02485f3d09c37fb13b1567367220a720bcc9a5"

# Notification address
email="jeezusjr@gmail.com"

# Repository path and name
repo_basename="archzfs"
repo_basepath="/repo"
repo_remote_basepath="/home/jalvarez/webapps/default"

# SSH login address (can use ssh config Hosts)
remote_login="webfaction"

# The signing key to use to sign packages
gpg_sign_key='0EE7A126'

chroot_path="/repo/chroot/x86_64/$(whoami)"

# Used to run mkaurball and mksrcinfo with lower privledges
makepkg_nonpriv_user="demizer"
