=====================
archzfs testing guide
=====================
:Modified: Sun Jan 29 14:08 2017

--------
Overview
--------

* Hosted at archzfs.com

  archzfs.com for the project webpage (webfaction)
  archzfs.com/repo for the repo (webfaction)
  build.archzfs.com for jenkins
  deploy.archzfs.com custom webpage for deploying valid builds (local server)

* Bulder hardware Intel Xeon v3 with 16GB of ECC RAM @ home in DMZ

* Build a qemu base image using packer

* Provision a test environment with script, perform regression tests

  Regression test suite (http://zfsonlinux.org/zfs-regression-suite.html)

  Test booting into a zfs root filesystem

* MAYBE: deploy.archzfs.com for pushing packages to AUR and the archzfs package repo

  2fa login

  Shows complete list of changes from zfsonlinux git

  Shows all log output from builders and tests

  One button deploy

------------
Requirements
------------

To run the test automation, the following items are required:

* Reflector

  For selecting a fast mirror.

* nfs (pacman package cache)

  Be a good netizen and only download binaries once.

* packer

  Used to build the base image from the latest archiso. Install from AUR.

* sshpass

  To allow automated ssh logins.

* ksh

  From AUR, needed for zfs-test

* python2.6

  From AUR, needed for zfs-test

----------------------
Build and test process
----------------------

Stage 1
=======

1. Build the packages using the normal build process, but without signing.

   Build on local machine and copy the packages to the test environment.

   ccm64 command will need to be run without root priviledges.

#. Use packer to create a test instance with the zfs packages installed

#. Perform regression tests

Stage 2
=======

1. Use packer to build zfs root filesystem test instances

   packer configurations for:

   a. zfs single root filesystem

   #. zfs with storage pool as root filesystem

   #. zfs root with legacy mounts

---------------------------------------
Packer/KVM build/test environment setup
---------------------------------------

The goal of this article is to setup a qemu based testing environment for the
archzfs project.

This guide provides details on setting up VM's for multiple zfs usage
scenarios.

-------------
Helpful links
-------------

* http://blog.falconindy.com/articles/build-a-virtual-army.html

--------
Packages
--------

1. qemu

----------
Qemu Setup
----------

1. Check kvm compatibility

.. code:: bash

   $ lscpu | grep Virtualization

#. Load kernel modules

.. code:: bash

   # modprobe -a kvm tun virtio

#. Install qemu

.. code:: bash

   # pacman -Sy qemu

nfs
===

::

    /var/cache/pacman/pkg   127.0.0.1(rw,async,no_root_squash,no_subtree_check,insecure)

qemu sends packets from 127.0.0.1:44730 to 127.0.0.1:2049 for mounting.
The insecure option allows packets from ports > 1024

How
===

1. The archzfs-linux packages are built for the linux kernel and added to a package repository named "archzfs-testing".

#. The archzfs-testing repo is shared over NFS.

#. A custom archiso is built that boots into the linux-lts kernel.

#. The test files are compressed into a tar archive.

#. Packer is used to build a qemu base image using the custom archiso.

#. `setup.sh` is ran in the archiso to install arch on ZFS.

#. After installation of Arch on ZFS, the VM is rebooted and packer finalizes the base image.

#. The qemu base image created by packer is booted, if the boot is successful, the test is considered passed.

Adding a new test
=================

While adding a new automated test is not as easy, it is extremely beneficial to the project. So if one is so inclined, please
consider helping us all!

Copy one of the existing tests to a new directory. The name of the test is important, so follow this naming scheme::

    archzfs-qemu-<pkg_group>-test-<number>-<short_description>

If defining a brand new test for a brand new kernel, please use `test-00-default-<desc>` for the standard archzfs use case of
booting from ext4 and mounting a zfs data device. Use `test-00-boot-<desc>` to define a test that boots from archzfs.

Once this is done edit the various files to sorta get what you want. There are a few files that will probably be edited
most::

    conf.sh
    fs.sh
    hooks.sh


This is the most difficult part because it is necessary to define an installation for Arch Linux through a series of commands
that will run through packer/qemu.  `testing/archzfs-qemu-base/setup.sh` is the script run in the archiso to install arch. It
loads the files defined in the test and calls each of the "hooks" in turn. Similar to how PKGBUILDs work with makepkg.

Finally, run your test from the root project directory::

    # testing/test.sh -d std-test-00-default

You should see packer start archiso in qemu and begin previsioning the device. Once packer is done, the device will reboot
and the acceptance criteria will determine if the test succeeded.

If you think any of these steps can be done simpler and/or more efficiently, please open an issue!

----------------------------------
Setting up Testing for ZOL 0.6.5.8
----------------------------------
:Date: Sun Sep 11 17:08 2016

This is an example session where I setup tests for ZOL 0.6.5.8. I will be setting up two tests, a simple test where zfs is
used for a data volume and a complex test where archzfs is used as a boot filesystem.

The upstream ZOL maintainers released 0.6.5.8 that supports linux 4.7 and 4.8. Now that archzfs has a working example for an
automated test for archzfs-linux-lts, let's use the same test setup for the standard archzfs packages and this new ZOL
version. Since it is nontrivial to setup a new automated test, I want to record these steps for anyone that may take up the
noble task in the future.

Test #1: ZFS data volume in Arch Linux
======================================

There are a few test criteria for this first test:

1. Boot into a regular arch system with the archzfs packages already installed.
#. Create a new zpool and mount it.
#. Write some data to it and reboot.
#. After reboot make sure the pool is automatically mounted data is still there.

If all of these criteria are met, the test is a success.

Another key area I am going to look at is the changes made to the systemd scripts reported by bronek via
https://github.com/archzfs/archzfs/issues/72. How will these changes impact

Deploying the archzfs-linux packages to the archzfs-testing repo
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

This is the easiest part, all that needed to be done was to increment the version number in `src/kernels/linux.sh` and build
using `./build.sh std update make -u -U` once this was done the packages were added to the `archzfs-testing` repo using
`./repo std test`. This repo is mounted in the archiso and arch-chroot via NFS using the test setup scripts.

Copying the files
+++++++++++++++++

Most of the work to use packer to build a base image has been done previously for an archzfs-linux-lts test, so we'll reuse
that configuration and modify it to boot into a regular arch linux installation on ext4.

The files that were modified were::

    fs.sh
    conf.sh
    config.sh
    syslinux.cfg
    boot.sh
    chroot.sh

Booting the base image
++++++++++++++++++++++

Booting the qemu image:

.. code:: console

    sudo /usr/bin/qemu-system-x86_64 -device virtio-net,netdev=user.0 \
        -drive file=testing/files/packer_work/output-qemu/archzfs-qemu-std-test-00-default-archiso-2016.09.10,if=virtio,cache=writeback,discard=ignore \
        -vnc 0.0.0.0:32 -netdev user,id=user.0,hostfwd=tcp::3333-:22 \
        -name archzfs-qemu-std-test-00-default-archiso-2016.09.10 -machine type=pc,accel=kvm -display sdl -boot once=d -m 512M

Connection via ssh:

.. code:: console

    ssh root@10.0.2.15 -p 3333

Password is `azfstest`

Attempting to run `zpool status` results in::

    [root@test ~]# zpool status
    The ZFS modules are not loaded.
    Try running '/sbin/modprobe zfs' as root to load them.

Let's make zfs start automatically on boot via the base image setup scripts.

But first, we must understand the updated systemd configuration for ZFSonLinux.

Running `pacman -Ql zfs-linux` show the systemd files::

    zfs-utils-linux /usr/lib/systemd/
    zfs-utils-linux /usr/lib/systemd/system-preset/
    zfs-utils-linux /usr/lib/systemd/system-preset/50-zfs.preset
    zfs-utils-linux /usr/lib/systemd/system/
    zfs-utils-linux /usr/lib/systemd/system/zfs-import-cache.service
    zfs-utils-linux /usr/lib/systemd/system/zfs-import-scan.service
    zfs-utils-linux /usr/lib/systemd/system/zfs-mount.service
    zfs-utils-linux /usr/lib/systemd/system/zfs-share.service
    zfs-utils-linux /usr/lib/systemd/system/zfs-zed.service
    zfs-utils-linux /usr/lib/systemd/system/zfs.target

Particularly, let's look at `50-zfs.preset`. This is the file used by the upstream maintainers to configure systemd to
autostart ZFS system at boot. The Arch ethos forbids starting a process unless not initiated by the user and this is
hardcoded into the systemd arch installation by default::

    [root@test ~]# cat /usr/lib/systemd/system-preset/99-default.preset
    disable *

This file will disable all autoloaded systemd units.

* `Enable installed units by default <https://wiki.archlinux.org/index.php/systemd#Enable_installed_units_by_default>`_

In our case, we should at least enable the kernel module at boot so the user can at least issue zfs commands.

So this was added to the zfs-utils packages in `src/zfs-utils/PKGBUILD.sh`. We autoload the zfs kernel module by placing a
config file in `/etc/modules-load.d/zfs.conf`. Now zfs can be used after installation and first reboot.

.. Creating an disk for zfs:

.. .. code:: console

    .. sudo  qemu-img create -f qcow2 output-qemu/archzfs-qemu-std-test-00-default-archiso-2016.09.10 122880M

