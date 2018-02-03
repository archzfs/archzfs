#!/bin/bash

systemd_old_version="0.7.4-1"
if [[ ${archzfs_package_group} =~ -git$ ]]; then
    systemd_old_version="2017.12.08.r3208.4e9b15696-1"
fi
systemd_warning="
    # If upgrading from $systemd_old_version or older
    # display zfs-import warning
    if [[ \$(vercmp \$2 $systemd_old_version) -le 0 ]]; then
        echo '>>> WARNING: A new systemd unit file was added to archzfs!'
        echo '>>>          You may need enable zfs-import.target'
        echo '>>>          See https://github.com/archzfs/archzfs/issues/186'
    fi"


encryption_warning=""
if [[ ${archzfs_package_group} =~ -git$ ]]; then
    encryption_old_version="2018.02.02.r3272.1b66810ba-1"
    encryption_warning="
    # If upgrading from $encryption_old_version or older
    # display encryption format change warning
    if [[ \$(vercmp \$2 $encryption_old_version) -le 0 ]]; then
        echo '>>> WARNING: The on-disk format for encrypted datasets has changed!'
        echo '>>>          All encrypted datasets will mount read only and need to be migrated.'
        echo '>>>          See https://github.com/archzfs/archzfs/issues/222'
    fi"
fi

    
cat << EOF > ${zfs_utils_pkgbuild_path}/zfs-utils.install
post_upgrade() {
    ${systemd_warning}
    ${encryption_warning}
}
EOF
