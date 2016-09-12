#
test_vm_boot() {
    # $1 the image to boot
    # /usr/bin/qemu-system-x86_64 -device virtio-net,netdev=user.0 \
        # -drive file=testing/files/packer_work/output-qemu/archzfs-qemu-std-test-00-default-archiso-2016.09.10,if=virtio,cache=writeback,discard=ignore \
        # -vnc 0.0.0.0:32 -netdev user,id=user.0,hostfwd=tcp::3333-:22 \
        # -name archzfs-qemu-std-test-00-default-archiso-2016.09.10 -machine type=pc,accel=kvm -display sdl -boot once=d -m 512M
}

# Configure
test_vm_config_zfs_zpool() {

    # ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@localhost -p 3543

    # TODO NEED TO CREATE NEW QEMU VOL

    # zpool create -m /bigdata -f zroot /dev/vdb1


    # run_cmd "zfs create -o mountpoint=none zroot/ROOT"
    # run_cmd "zfs create -o compression=lz4 -o mountpoint=${test_target_dir}/ROOT zroot/ROOT/default"
    # run_cmd "zfs create -o mountpoint=none zroot/data"
    # run_cmd "zfs create -o compression=lz4 -o mountpoint=${test_target_dir}/ROOT/home zroot/data/home"
    # run_cmd "zfs set mountpoint=legacy zroot/data/home"

    # msg2 "Mounting /home"
    # run_cmd "mount -t zfs -o default,noatime zroot/data/home ${test_target_dir}/ROOT/home"

    # msg2 "Create boot directory"

    # run_cmd "mkdir -p ${test_target_dir}/ROOT/boot"

    # msg2 "Unmounting home partition"
    # run_cmd "umount ${test_target_dir}/ROOT/home"

    # msg2 "Setting flags and exporting ZFS root"
    # run_cmd "zfs umount -a"
    # run_cmd "zpool set bootfs=zroot/ROOT/default zroot"
    # run_cmd "zfs set mountpoint=none zroot"
    # run_cmd "zfs set mountpoint=/ zroot/ROOT/default"
    # run_cmd "zfs set mountpoint=/home zroot/data/home"
    # run_cmd "zfs set mountpoint=legacy zroot/data/home"
    # run_cmd "zpool export zroot"
}


