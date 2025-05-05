# OpenZFS stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
openzfs_version="2.3.1"
openzfs_rc_version="2.3.0-rc5"

# The OpenZFS source hashes are from github.com/openzfs/zfs/releases
zfs_src_hash="053233799386920bdc636e22d0e19a8c2c3e642e8bd847ff87e108f8bb1f9006"
zfs_rc_src_hash="dee425d07b28ede44092d41b7244cc9847110e61862772e9faa51b0180e96f52"

zfs_initcpio_install_hash="d19476c6a599ebe3415680b908412c8f19315246637b3a61e811e2e0961aea78"
zfs_initcpio_hook_hash="569089e5c539097457a044ee8e7ab9b979dec48f69760f993a6648ee0f21c222"
zfs_initcpio_zfsencryptssh_install="93e6ac4e16f6b38b2fa397a63327bcf7001111e3a58eb5fb97c888098c932a51"

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
makepkg_nonpriv_user="buildbot"
