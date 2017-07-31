# Requires the pacman cache and pacman package repos be mounted via NFS
test_pacman_config() {
    # $1 arch-chroot target directory
    arch_target_dir=""
    arch_packages="${test_archiso_packages}"
    if [[ -n $1 ]]; then
        arch_target_dir="${1}"
        arch_chroot="/usr/bin/arch-chroot ${1}"
    fi

    msg "Overriding mirrorlist"
    run_cmd "cp mirrorlist ${arch_target_dir}/etc/pacman.d/mirrorlist"

    msg "Installing archzfs repo into chroot"
    printf "\n%s\n%s\n" "[${test_archzfs_repo_name}]" "Server = file:///repo/\$repo/\$arch" >> ${arch_target_dir}/etc/pacman.conf

    msg2 "Setting up gnupg"
    run_cmd "${arch_chroot} dirmngr < /dev/null"

    # Wait for networking
    for i in `seq 1 10`; do
        if [[ check_internet -eq 0 ]]; then
            break
        fi
        msg2 "Attempt $i -- Google.com did not respond, trying again in 3 seconds..."
        sleep 3
        if [[ $i == "10" ]]; then
            error "Tried 10 times, giving up!"
            exit 1
        fi
    done

    msg2 "Installing the signer key"
    run_cmd "${arch_chroot} pacman-key -r 0EE7A126"
    run_cmd_check 1

    run_cmd "${arch_chroot} pacman-key --lsign-key 0EE7A126"
    run_cmd_check 1

    if [[ ! -n $1 ]]; then
        msg2 "Installing test packages"
        # Install the required packages in the image
        run_cmd "${arch_chroot} pacman -Sy --noconfirm ${arch_packages}"
        run_cmd_check 1
        msg2 "Loading zfs modules"
        run_cmd "modprobe zfs"
    fi
}


test_pacman_pacstrap() {
    msg "bootstrapping the base installation"
    debug "TEST_CHROOT_PACKAGES: ${test_chroot_packages}"
    run_cmd "/usr/bin/pacstrap -c '${test_target_dir}/ROOT' base base-devel ${test_chroot_packages}"
    run_cmd_check 1
}
