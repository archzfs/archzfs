# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="0.8.3"
zol_rc_version="0.8.0-rc5"

# The ZOL source hashes are from zfsonlinux.org
zfs_src_hash="545a4897ce30c2d2dd9010a0fdb600a0d3d45805e2387093c473efc03aa9d7fd"
zfs_rc_src_hash="c5dc91e3efb7555c6c1846cf89fd4cfb0952271a2900434e697f2b7397ce9b16"

zfs_initcpio_install_hash="29a8a6d76fff01b71ef1990526785405d9c9410bdea417b08b56107210d00b10"
zfs_initcpio_hook_hash="78e038f95639c209576e7fa182afd56ac11a695af9ebfa958709839ff1e274ce"
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
