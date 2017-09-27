#!/bin/bash

cat << EOF > ${zfs_pkgbuild_path}/zfs.install
post_install() {
    check_initramfs
}

post_remove() {
    check_initramfs 'remove'
}

post_upgrade() {
    check_initramfs
}

check_initramfs() {
    echo ">>> Updating ZFS module dependencies"
    depmod -a \$(cat /usr/lib/modules/${kernel_mod_path}/version)
    
    MK_CONF=\$(grep -v '#' /etc/mkinitcpio.conf | grep zfs >/dev/null; echo \$?);
    if [[ \${MK_CONF} == '0' && \$1 == 'remove' ]]; then
        echo '>>> The ZFS packages have been removed, but "zfs" remains in the "hooks"'
        echo '>>> list in mkinitcpio.conf! You will need to remove "zfs" from the '
        echo '>>> "hooks" list and then regenerate the initial ramdisk.'
    fi
}
EOF
