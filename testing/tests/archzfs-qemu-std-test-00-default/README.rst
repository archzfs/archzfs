=====================================
Test archzfs-qemu-std-test-00-default
=====================================

Installs archzfs onto an ext4 bootable vm and verifies a zpool mounts correctly at boot.

--------
Overview
--------

Builds a custom archiso with the linux-lts kernel used by packer to create a Qemu base image. Syslinux is used as the boot
loader.

