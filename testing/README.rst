=====================
archzfs testing guide
=====================
:Modified: Sun Sep 04 10:04 2016

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
+++++++

1. Build the packages using the normal build process, but without signing.

   Build on local machine and copy the packages to the test environment.

   ccm64 command will need to be run without root priviledges.

#. Use packer to create a test instance with the zfs packages installed

#. Perform regression tests

Stage 2
+++++++

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
+++

::

    /var/cache/pacman/pkg   127.0.0.1(rw,async,no_root_squash,no_subtree_check,insecure)

qemu sends packets from 127.0.0.1:44730 to 127.0.0.1:2049 for mounting.
The insecure option allows packets from ports > 1024

-----
Notes
-----

- Sun Apr 19 19:45 2015: Found more tests at https://github.com/behlendorf/xfstests

  Requires additional pools

- Sun Apr 19 19:51 2015: ztest slides http://blog.delphix.com/csiden/files/2012/01/ZFS_Backward_Compatability_Testing.pdf

- Sun Apr 19 20:05 2015: What I am trying to do is described here: https://github.com/zfsonlinux/zfs/issues/1534

