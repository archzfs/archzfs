====================================
Zettabyte File System for Arch Linux
====================================
:Modified: Sun Sep 11 18:01 2016

Welcome to the archzfs project. This repo contains everything used to deploy ZFS to Arch Linux.

--------
Overview
--------

WIP

.. The Git packages include zfs-git, zfs-utils-git, spl-git, and spl-utils-git. These track the mainline kernel releases in
.. arch. Since Arch is bleeding edge, so too are these packages. They usually pull from zfsonlinux master branch up to the
.. latest commit that add supports for latest kernel version.

.. The LTS packages include zfs-lts, zfs-utils-lts, spl-lts, and spl-utils-lts. These track the linux-lts packages in arch and
.. are only built using stable zfsonlinux releases. These packages are the best bet for those concerned with stability.

.. These packages must be re-built for each kernel release.

------------
Dependencies
------------

Building
++++++++

* `clean-chroot-manager`_ to build packages in a systemd namespace container

Testing
+++++++

Dependencies used by the `test.sh` command.

* QEMU
* Packer
* NFS

--------------------------
How to use this Repository
--------------------------

*WIP*

.. Clone
.. +++++

.. .. code:: console

   .. git clone https://github.com/archzfs/archzfs.git --recursive

.. Submitting changes
.. ++++++++++++++++++

.. T

.. Update
.. ++++++

.. 1. Set the appropriate variables in conf.sh

   .. * Repository base path

     .. The parent directory of the ``demz-repo-core`` and ``demz-repo-archiso``
     .. repos.

   .. * GPG signing key

     .. Used to sign the packages and repo database.

   .. * Your email address

     .. Used for reporting changes changes in ``scraper.sh``. Mutt and msmtp are
     .. used for sending email. Required only if ``scraper.sh`` or ``verifier.sh``
     .. are going to be used.

   .. * SSH remote login

     .. Used in ``verifier.sh`` for making sure the local ``demz-repo-*`` are in
     .. sync with the remote repos.

.. #. Set the appropriate kernel versions in conf.sh.

.. #. Update the PKGBUILDs

   .. Use ``./build git update`` to update the archzfs-git PKGBUILDS using the
   .. ``conf.sh`` variables.

   .. Use ``./build lts update`` to update the archzfs-lts PKGBUILDS using the
   .. ``conf.sh`` variables.

   .. ``./build.sh (git|lts) update-test`` uses the ``AZB_LINUX_TEST_*``
   .. variables. Using the test values are useful for test building the zfs
   .. packages against the Linux kernel version in the official testing repo.
   .. Mostly used on minor Linux kernel updates (3.12 -> 3.13).

.. #. Build the packages

   .. Use ``./build.sh (git|lts) make -u`` to build the packages, update the clean
   .. chroot in the process.

   .. It is possible to use ``./build.sh (git|lts) update make -u`` in one shot.

   .. If you want to see command output only, use ``./build.sh (git|lts) make
   .. -n``. Add the ``-d`` to see debugging output.

.. #. Add packages to the repo

   .. Use ``./repo.sh (git|lts) core -n`` to what changes will occur without
   .. actually making them.

   .. ``./repo.sh (git|lts) core`` will add the package versions defined by
   .. ``AZB_LINUX_VERSION`` to the ``demz-repo-core`` repository.

.. #. Push the package sources to AUR.

   .. Push to AUR4 using ``push.sh (git|lts) aur4``. This commits the latest
   .. changes to each individual package repo (for AUR) and uses ``git push`` to
   .. push to AUR.

--------
Licenses
--------

The license of the Arch Linux package sources is MIT.

The license of ZFS is CDDL.

The license of SPL is LGPL.

.. _clean-chroot-manager: https://aur.archlinux.org/packages/clean-chroot-manager
