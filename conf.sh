# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="0.7.13"
zol_rc_version="0.8.0-rc4"

# The ZOL source hashes are from zfsonlinux.org
spl_src_hash="6fd4445850ac67b228fdd82fff7997013426a1c2a8fa9017ced70cc9ad2a4338"
zfs_src_hash="d23f0d292049b1bc636d2300277292b60248c0bde6a0f4ba707c0cb5df3f8c8d"
zfs_rc_src_hash="2a006686c0cf4360fbc1352cbf82ecd69a5029555bb038d23fbf5ad5d49359ba"

zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
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
makepkg_nonpriv_user="demizer"
