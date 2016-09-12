test_fs_config_nfs() {
    # $1 arch-chroot directory
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
    run_cmd "sgdisk --new=1:0:0 --typecode=1:8300 ${disk}"

    msg2 "Making root partition bootable"
    run_cmd "sgdisk --attributes=1:set:2 ${disk}"

    msg2 "The disk"
    run_cmd "sgdisk -p ${disk}"

    msg2 "Creating / filesystem (ext4)"
    run_cmd "mkfs.ext4 -O ^64bit -F -m 0 -q -L root /dev/vda1"

    msg2 "Mounting root filesystem"
    run_cmd "/usr/bin/mkdir -p ${test_target_dir}/ROOT"
    run_cmd "mount -o noatime,errors=remount-ro /dev/vda1 ${test_target_dir}/ROOT/"
}


test_fs_config_root_postinstall() {
    msg "Performing final filesystem operations"

    msg2 "Unmounting nfs partitions"
    run_cmd "umount -a -t nfs4"

    msg2 "Unmounting root partition"
    run_cmd "umount ${test_target_dir}/ROOT"
}
