#!/bin/bash

export test_root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
debug "test_root_dir='${test_root_dir}'"

export test_target_dir='/mnt'

export test_archzfs_repo_name="archzfs-testing"

# Additional packages to install in the archiso
export test_archiso_packages="archzfs-linux-lts"

# Additional packages to install in the archiso. The 'packages' file is placed in /root on the archiso qemu environment.
export test_chroot_packages="$(< packages) archzfs-linux-lts"

export fqdn='test.archzfs.test'
export keymap='us'
export language='en_US.UTF-8'
export password=$(/usr/bin/openssl passwd -crypt 'azfstest')
export timezone='UTC'
