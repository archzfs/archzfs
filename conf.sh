# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="2.0.3"
zol_rc_version="2.0.0-rc7"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="0694f64aa76a3a0a506e20e99b49102c3cb68bef63cb0f0154e50befc387e539"
zfs_rc_src_hash="640fde2b678040c9511172bf3b7ffc444d8e8daa1d738f4687f1ad92d6d01e7b"

zfs_initcpio_install_hash="29a8a6d76fff01b71ef1990526785405d9c9410bdea417b08b56107210d00b10"
zfs_initcpio_hook_hash="449a6db4abd3f166562bb67a63950af053e9ec07eabbfcdff827c5ed0113a2d6"
zfs_initcpio_zfsencryptssh_install="29080a84e5d7e36e63c4412b98646043724621245b36e5288f5fed6914da5b68"

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
