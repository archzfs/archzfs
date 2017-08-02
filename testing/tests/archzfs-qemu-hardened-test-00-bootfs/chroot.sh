test_chroot_setup() {
    # $1 arch-chroot target dir
    msg "Setting up arch install..."
    export arch_target_dir="${test_target_dir}"
    if [[ -n $1 ]]; then
        arch_target_dir="${1}"
    fi
    msg2 "Setting base image pacman mirror"
    run_cmd "/usr/bin/cp /etc/pacman.d/mirrorlist ${arch_target_dir}/etc/pacman.d/mirrorlist"

    msg2 "generating the filesystem table"
    run_cmd "/usr/bin/genfstab -p ${arch_target_dir} >> '${arch_target_dir}/etc/fstab'"

    # http://comments.gmane.org/gmane.linux.arch.general/48739
    msg2 "Adding workaround for shutdown race condition"
    run_cmd "/usr/bin/install --mode=0644 poweroff.timer '${arch_target_dir}/etc/systemd/system/poweroff.timer'"

    msg2 "Create config.sh"
    run_cmd "/usr/bin/install --mode=0755 /dev/null '${arch_target_dir}/usr/bin/config.sh'"

    # Special filesystem configure script
    source_safe /root/test-config.sh

    msg2 "Entering chroot and configuring system"
    run_cmd "/usr/bin/arch-chroot ${arch_target_dir} /usr/bin/config.sh"

    msg2 "Deleting config.sh"
    rm ${arch_target_dir}/usr/bin/config.sh
}
