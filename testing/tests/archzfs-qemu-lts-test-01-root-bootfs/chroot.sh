export fqdn='test.archzfs.test'
export keymap='us'
export language='en_US.UTF-8'
export password=$(/usr/bin/openssl passwd -crypt 'azfstest')
export timezone='UTC'


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

    msg2 "Create base.sh"
    run_cmd "/usr/bin/install --mode=0755 /dev/null '${arch_target_dir}/usr/bin/base.sh'"

    # http://comments.gmane.org/gmane.linux.arch.general/48739
    msg2 "Adding workaround for shutdown race condition"
    run_cmd "/usr/bin/install --mode=0644 poweroff.timer '${arch_target_dir}/etc/systemd/system/poweroff.timer'"

    # Special filesystem configure script
    source_safe /root/base.sh

    msg2 "Entering chroot and configuring system"
    run_cmd "/usr/bin/arch-chroot ${arch_target_dir} base.sh"

    msg2 "Deleting base.sh"
    rm ${arch_target_dir}/usr/bin/base.sh
}
