# OpenZFS stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
openzfs_version="2.2.6"
openzfs_rc_version="2.1.0-rc8"

# The OpenZFS source hashes are from github.com/openzfs/zfs/releases
zfs_src_hash="c92e02103ac5dd77bf01d7209eabdca55c7b3356aa747bb2357ec4222652a2a7"
zfs_rc_src_hash="8627702ac841d38d5211001c76937e4097719c268b110e8836c0da195618fad2"

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
makepkg_nonpriv_user="jan"
