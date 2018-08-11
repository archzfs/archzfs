# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="0.7.9"

# The ZOL source hashes are from zfsonlinux.org
spl_src_hash="49832e446a5abce0b55ba245c9b5f94959604d44378320fdffae0233bf1e8c00"
zfs_src_hash="f50ca2441c6abde4fe6b9f54d5583a45813031d6bb72b0011b00fc2683cd9f7a"

zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="335e309ebf5b74fd8956f5e8805939c37d4008b0bcc3b00be6e7ef1d5b7c1669"
zfs_initcpio_hook_hash="ee503075984b0f2a6c66d5bd5a2c015bcde462459d8b75690e623b0df93bdbd3"

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
