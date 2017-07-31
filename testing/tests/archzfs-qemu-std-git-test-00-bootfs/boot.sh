test_bootloader_install() {
    # Setup the boot loader
    run_cmd "mkdir -p ${arch_target_dir}/boot/syslinux; cp -f /root/syslinux.cfg '${arch_target_dir}/boot/syslinux/syslinux.cfg'"
    run_cmd "arch-chroot ${arch_target_dir} /usr/bin/syslinux-install_update -i -a -m"
    run_cmd_check 1
}
