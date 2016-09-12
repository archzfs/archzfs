
# From old arch-config.sh

    # # zfs-test configuration
    # # /usr/bin/groupadd zfs-tests
    # # /usr/bin/useradd --comment 'ZFS Test User' -d /var/tmp/test_results --create-home --gid users --groups zfs-tests zfs-tests

    # # sudoers.d is the right way, but the zfs test suite checks /etc/sudoers...
    # echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_zfs_test
    # echo 'zfs-tests ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_zfs_test
    # /usr/bin/chmod 0440 /etc/sudoers.d/10_zfs_test
