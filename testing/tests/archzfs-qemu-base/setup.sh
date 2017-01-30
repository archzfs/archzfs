#!/usr/bin/env bash


export script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${script_dir}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 155
fi


export debug_flag=1
export dry_run=0


# source_safe "${script_dir}/archzfs-conf.sh"
source_safe "${script_dir}/test-conf.sh"
source_safe "${script_dir}/test-archiso.sh"
source_safe "${script_dir}/test-boot.sh"
source_safe "${script_dir}/test-chroot.sh"
source_safe "${script_dir}/test-fs.sh"
source_safe "${script_dir}/test-hooks.sh"
source_safe "${script_dir}/test-pacman.sh"


# Install nfs mount points to the archiso environment
test_fs_config_nfs


# Install the archzfs repo to the archiso environment
test_pacman_config


# Install the zfs root filesystem for the test
test_fs_config_root_preinstall


# Install base packages into the chroot
test_pacman_pacstrap


# Install nfs mount points to the arch chroot environment
test_fs_config_nfs "/mnt/ROOT"


# Configure pacman for the arch chroot environment
test_pacman_config "/mnt/ROOT"


# Finish installing arch in the chroot environment
test_chroot_setup "/mnt/ROOT"


# Install the boot loader!
test_bootloader_install


# Filesystem things to do after installation
test_fs_config_root_postinstall


# Reboot!
test_setup_exit


# TODO: Manage packer output here. We need to boot the built base image and run tests on it.


# Check acceptance criteria
if ! test_met_acceptance_criteria; then
    error "Test failed!"
    exit 1
fi
