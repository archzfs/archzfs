test_pacman_config() {
    msg "Setting archiso pacman mirror"
    # /usr/bin/cp mirrorlist /etc/pacman.d/mirrorlist

    # setup pacman repositories in the archiso
    # msg "Installing local pacman package repositories"
    # test_pacman_config /etc/pacman.conf

    # dirmngr < /dev/null
    # pacman-key -r 0EE7A126
    # if [[ $? -ne 0 ]]; then
        # exit 1
    # fi
    # pacman-key --lsign-key 0EE7A126
    # pacman -Sy archzfs-archiso-linux
    # modprobe zfs
}


