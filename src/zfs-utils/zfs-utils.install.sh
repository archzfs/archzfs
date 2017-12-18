#!/bin/bash

old_version="0.7.4-1"
if [[ ${archzfs_package_group} =~ -git$ ]]; then
    old_version="2017.12.08.r3208.4e9b15696-1"
fi
    
cat << EOF > ${zfs_utils_pkgbuild_path}/zfs-utils.install

show_zfs_import_warning() {
    echo ">>> WARNING: A new systemd unit file was added to archzfs!"
    echo ">>>          You may need enable zfs-import.target"
    echo ">>>          See https://github.com/archzfs/archzfs/issues/186"
}

post_upgrade() {
    # If upgrading from $old_version or older
    # display zfs-import warning
    if [[ \$(vercmp \$2 $old_version) -le 0 ]]; then
        show_zfs_import_warning
    fi
}
EOF
