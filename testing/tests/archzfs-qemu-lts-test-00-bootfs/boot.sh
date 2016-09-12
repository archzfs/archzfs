test_bootloader_install() {
    # Setup the boot loader
    run_cmd "mkdir -p ${arch_target_dir}/boot/syslinux; cp -f /root/syslinux.cfg '${arch_target_dir}/boot/syslinux/syslinux.cfg'"
    run_cmd "arch-chroot ${arch_target_dir} /usr/bin/syslinux-install_update -i -a -m"
    if [[ ${run_cmd_return} -ne 0 ]]; then
        exit 1
    fi
}
