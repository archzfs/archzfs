#!/bin/bash

cat << EOF > ${zfs_dkms_pkgbuild_path}/zfs.install
post_install() {
    # https://bugs.archlinux.org/task/52901
    echo '>>> If DKMS fails to build ZFS, run this command:'
    echo -e '# dkms install -m zfs/${zfs_mod_ver} -k <kernel_version>\n'
    
    echo 'If you are using ZFS on your root partition run this afterwards:'
    echo '# mkinitcpio -P'
}

post_upgrade() {
    post_install "\$1"
}
EOF
