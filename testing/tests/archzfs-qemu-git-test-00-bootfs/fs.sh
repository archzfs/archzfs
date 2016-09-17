test_fs_config_nfs() {
    # $1 arch-chroot directory
    # prefix="${test_target_dir}"
    if [[ -n $1 ]]; then
        prefix="${1}"
    fi

    msg "Create NFS mount points"
    run_cmd "/usr/bin/mkdir -p ${prefix}/repo"

    msg "Setting the package cache (nfs mount)"
    run_cmd "mount -t nfs4 -o rsize=32768,wsize=32768,timeo=3 10.0.2.2:/var/cache/pacman/pkg ${prefix}/var/cache/pacman/pkg"

    msg "Mounting the AUR package repo"
    run_cmd "mount -t nfs4 -o rsize=32768,wsize=32768,timeo=3 10.0.2.2:/mnt/data/pacman/repo ${prefix}/repo"
}


test_fs_config_root_preinstall() {
    msg "Configuring root filesystem!"

    export disk='/dev/vda'
    export root_partition="${disk}1"

    msg2 "Clearing partition table on ${disk}"
    run_cmd "sgdisk --zap ${disk}"

    msg2 "Destroying magic strings and signatures on ${disk}"
    run_cmd "dd if=/dev/zero of=${disk} bs=512 count=2048"
    run_cmd "wipefs --all ${disk}"

    # See http://www.rodsbooks.com/gdisk/sgdisk-walkthrough.html
    # http://www.rodsbooks.com/gdisk/sgdisk.htm
    msg2 "Creating boot partition on ${disk}"
    run_cmd "sgdisk --new=1:0:512M --typecode=1:8300 ${disk}"

    msg2 "Creating root partition on ${disk}"
    run_cmd "sgdisk --new=2:0:0 --typecode=2:bf00 ${disk}"

    msg2 "The disk"
    run_cmd "sgdisk -p ${disk}"

    msg2 "Creating root filesystem"
    run_cmd "zpool create -m ${test_target_dir} -f zroot /dev/vda2"
    run_cmd "zfs create -o mountpoint=none zroot/ROOT"
    run_cmd "zfs create -o compression=lz4 -o mountpoint=${test_target_dir}/ROOT zroot/ROOT/default"
    run_cmd "zfs create -o mountpoint=none zroot/data"
    run_cmd "zfs create -o compression=lz4 -o mountpoint=${test_target_dir}/ROOT/home zroot/data/home"
    run_cmd "zfs set mountpoint=legacy zroot/data/home"

    msg2 "Mounting /home"
    run_cmd "mount -t zfs -o default,noatime zroot/data/home ${test_target_dir}/ROOT/home"

    msg2 "Create boot directory"
    run_cmd "mkdir -p ${test_target_dir}/ROOT/boot"

    msg2 "Creating /boot filesystem (ext4)"
    run_cmd "mkfs.ext4 -F -m 0 -q -L boot /dev/vda1"

    msg2 "Mounting boot filesystem"
    run_cmd "mount -o noatime,errors=remount-ro /dev/vda1 ${test_target_dir}/ROOT/boot"

}

test_fs_config_root_postinstall() {
    msg "Performing final filesystem operations"

    msg2 "Unmounting boot partition"
    run_cmd "umount ${test_target_dir}/ROOT/boot"

    msg2 "Unmounting nfs partitions"
    run_cmd "umount -a -t nfs4"

    msg2 "Unmounting home partition"
    run_cmd "umount ${test_target_dir}/ROOT/home"

    msg2 "Setting flags and exporting ZFS root"
    run_cmd "zfs umount -a"
    run_cmd "zpool set bootfs=zroot/ROOT/default zroot"
    run_cmd "zfs set mountpoint=none zroot"
    run_cmd "zfs set mountpoint=/ zroot/ROOT/default"
    run_cmd "zfs set mountpoint=/home zroot/data/home"
    run_cmd "zfs set mountpoint=legacy zroot/data/home"
    run_cmd "zpool export zroot"
}
