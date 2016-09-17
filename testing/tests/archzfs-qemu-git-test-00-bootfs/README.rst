=========================================
Test archzfs-qemu-lts-test-01-root-bootfs
=========================================

Tests all the steps required for archzfs-linux-lts to be used as a boot filesystem.

--------
Overview
--------

Builds a custom archiso with the linux-lts kernel used by packer to create a Qemu base image. Syslinux is used as the boot
loader.

---
How
---

1. The archzfs-linux-lts packages are built for the linux-lts kernel and added to a package repository named "archzfs-testing".

#. The archzfs-testing repo is shared over NFS.

#. A custom archiso is built that boots into the linux-lts kernel. See `Archiso customization`_

#. The test files are compressed into a tar archive.

#. Packer is used to build a qemu base image using the custom archiso.

#. `setup.sh` is ran in the archiso to install arch on ZFS.

#. After installation of Arch on ZFS, the VM is rebooted and packer finalizes the base image.

#. The qemu base image created by packer is booted, if the boot is successful, the test is considered passed.

---------------------
Archiso customization
---------------------

At the time of putting this test together (2016.09.03), there was no stable ZFSonLinux release that supported kernel 4.7 and
the archiso release at the time shipped with kernel 4.7. In order to install Arch on ZFS for test, I needed an archiso with
the linux-lts kernel. Thus, the archzfs-archiso was born!

The archiso is built by `test.sh` and used by packer to create a Qemu base image with ZFS as the root filesystem for testing.

The archiso comes with a bunch of features that are not needed in test, so they have been stripped out or modified. This
includes:

* boot straight into the linux-lts kernel to speed up the testing cycle.
* ZFS does not support arch-i686, so it was stripped.
* iPXE was not needed.

The archiso sources are copied from `/usr/share/archiso/configs/releng` after installation of the "archiso" package. The
modifed code is contained in the `testing/archiso-linux-lts` directory of this project.
