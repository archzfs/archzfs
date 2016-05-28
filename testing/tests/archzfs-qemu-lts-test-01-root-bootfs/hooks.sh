#!/bin/bash

setup_exit() {
    msg "Installation complete!"
    /usr/bin/sleep 10
    /usr/bin/umount /mnt/repo
    /usr/bin/umount /mnt/var/cache/pacman/pkg
    /usr/bin/umount ${arch_target_dir}
    /usr/bin/umount /var/cache/pacman/pkg
    /usr/bin/umount /repo
    /usr/bin/systemctl reboot
}
