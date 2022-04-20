# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="2.1.4"
zol_rc_version="2.1.0-rc8"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="3b52c0d493f806f638dca87dde809f53861cd318c1ebb0e60daeaa061cf1acf6"
zfs_rc_src_hash="8627702ac841d38d5211001c76937e4097719c268b110e8836c0da195618fad2"

zfs_initcpio_install_hash="600f49d610906476f492d53ee1830154e4ebedf999284485e07d9cb2b3084766"
zfs_initcpio_hook_hash="8b8c9b6ebfddfb51f2ab70fb943f53f08f6140140561efcb106120941edbc36e"
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
