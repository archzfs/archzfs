# OpenZFS stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
openzfs_version="2.4.4"

# RC packages are currently disabled. These retained values are not production
# release inputs; review the complete RC path before updating or re-enabling it.
openzfs_rc_version="2.4.0-rc1"

# The OpenZFS source hashes are from github.com/openzfs/zfs/releases
zfs_src_hash="2a3c70d55a37cc71618a95a60e81ad66530201eb118d37741dc92efcf848c8b1"
zfs_rc_src_hash="0068102a4162d7445b80218b882ff54e1acf3cfbeef909d53bd984ddcd9339b1"

zfs_initcpio_install_hash="6967f96cd6c21bf6c028b205e7cc556c1f436db87b977ff4037ee172b8cf84c2"
zfs_initcpio_hook_hash="eed2a00a24e56d878329270fad730e161bc89caa7bf8ade08b412cb1f68f7fb7"
zfs_initcpio_tpm2_provider_hash="77f5bb70426018f528fa7eaff4206a5b608df131b68913add8b0ebfa1f78af9c"
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
