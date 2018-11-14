# ZFSonLinux stable version
#
# FIXME: reset all kernel configs set to pkgrel=1 when this changes
#
zol_version="0.7.12"

# The ZOL source hashes are from zfsonlinux.org
spl_src_hash="4709a06e913bbbeb634161a8b68c3f879e5b6040c6c0c09b1f51042b3178c274"
zfs_src_hash="720e3b221c1ba5d4c18c990e48b86a2eb613575a0c3cc84c0aa784b17b7c2848"

zfs_bash_completion_hash="b60214f70ffffb62ffe489cbfabd2e069d14ed2a391fac0e36f914238394b540"
zfs_initcpio_install_hash="6e5e905a322d0426acdcbc05c5651ec78ee7b874b96d3c429c80f68b061170c5"
zfs_initcpio_hook_hash="78e038f95639c209576e7fa182afd56ac11a695af9ebfa958709839ff1e274ce"

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
