# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="0.8.5"
zol_rc_version="2.0.0-rc3"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="dbb41d6b9c606a34ac93f4c19069fd6806ceeacb558f834f8a70755dadb7cd3d"
zfs_rc_src_hash="d06ef8baa44a302ff28c6860e4ff1bf454c617198f755dbbce5d46d3bb7bca7b"

zfs_initcpio_install_hash="29a8a6d76fff01b71ef1990526785405d9c9410bdea417b08b56107210d00b10"
zfs_initcpio_hook_hash="b60bf208e2166266132180a8f21d295405617e30ebf3d0c7d15c251d7c0e92e8"
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
