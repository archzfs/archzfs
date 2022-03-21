# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="2.1.3"
zol_rc_version="2.1.0-rc8"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="b61b644547793f409cafd6538a52d78f2f72b0cd013e88340882457c8c9b43fd"
zfs_rc_src_hash="8627702ac841d38d5211001c76937e4097719c268b110e8836c0da195618fad2"

zfs_initcpio_install_hash="29a8a6d76fff01b71ef1990526785405d9c9410bdea417b08b56107210d00b10"
zfs_initcpio_hook_hash="ad3e7244aca20fce005860c5118d46a77a0b4f5644d73e9648ea3ba5ff87c4c3"
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
