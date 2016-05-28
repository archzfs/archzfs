===================
Archzfs Archiso LTS
===================

Used to create custom archiso with LTS kernel. Used only for testing archzfs. Supports only the x86_64 architecture.

How to use

.. code:: console

    # ./build.sh -v

to test with qemu,

.. code:: console

    # qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 -drive file=./out/archlinux-2016.09.04.iso,if=virtio,media=disk,format=raw
