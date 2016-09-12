Zettabyte File System for Arch Linux
====================================
:Modified: Sun Sep 11 18:01 2016

This project contains the build scripts for archzfs. Two types of packages are
supported, Git packages and LTS packages.

The Git packages include zfs-git, zfs-utils-git, spl-git, and spl-utils-git.
These track the mainline kernel releases in arch. Since Arch is bleeding edge,
so too are these packages. They usually pull from zfsonlinux master branch up
to the latest commit that add supports for latest kernel version.

The LTS packages include zfs-lts, zfs-utils-lts, spl-lts, and spl-utils-lts.
These track the linux-lts packages in arch and are only built using stable
zfsonlinux releases. These packages are the best bet for those concerned with
stability.

These packages must be re-built for each kernel release.

--------
Licenses
--------

The license of the Arch Linux package sources is MIT.

The license of ZFS is CDDL.

The license of SPL is LGPL.

------------
Dependencies
------------

``build.sh`` uses clean-chroot-manager_ to build packages in a systemd
namespace container.

--------------------------
How to use this Repository
--------------------------

Submitting changes
++++++++++++++++++

The Arch User Repository v4 requires package updates to be submitted through
Git. Unfortunately, this makes working with the archzfs build scripts on Github
slightly more complicated. The actual PKGBUILDS in the archzfs repo are set as
git submodules which reference the aur4 git repo and a commit hash. Github does
not support external submodules, and thus PR requests are no longer possible on
PKGBUILDS and mkinitcpio hook scripts.

Contributions are still very much appreciated! To submit a contribution, please
open an issue in Github and within the description post a git generated patch
of the changes. This is only temporary until AUR supports some kind of "pull
request" type system.

Clone
+++++

.. code:: console

   git clone https://github.com/archzfs/archzfs.git --recursive

Update
++++++

1. Set the appropriate variables in conf.sh

   * Repository base path

     The parent directory of the ``demz-repo-core`` and ``demz-repo-archiso``
     repos.

   * GPG signing key

     Used to sign the packages and repo database.

   * Your email address

     Used for reporting changes changes in ``scraper.sh``. Mutt and msmtp are
     used for sending email. Required only if ``scraper.sh`` or ``verifier.sh``
     are going to be used.

   * SSH remote login

     Used in ``verifier.sh`` for making sure the local ``demz-repo-*`` are in
     sync with the remote repos.

#. Set the appropriate kernel versions in conf.sh.

#. Update the PKGBUILDs

   Use ``./build git update`` to update the archzfs-git PKGBUILDS using the
   ``conf.sh`` variables.

   Use ``./build lts update`` to update the archzfs-lts PKGBUILDS using the
   ``conf.sh`` variables.

   ``./build.sh (git|lts) update-test`` uses the ``AZB_LINUX_TEST_*``
   variables. Using the test values are useful for test building the zfs
   packages against the Linux kernel version in the official testing repo.
   Mostly used on minor Linux kernel updates (3.12 -> 3.13).

#. Build the packages

   Use ``./build.sh (git|lts) make -u`` to build the packages, update the clean
   chroot in the process.

   It is possible to use ``./build.sh (git|lts) update make -u`` in one shot.

   If you want to see command output only, use ``./build.sh (git|lts) make
   -n``. Add the ``-d`` to see debugging output.

#. Add packages to the repo

   Use ``./repo.sh (git|lts) core -n`` to what changes will occur without
   actually making them.

   ``./repo.sh (git|lts) core`` will add the package versions defined by
   ``AZB_LINUX_VERSION`` to the ``demz-repo-core`` repository.

#. Push the package sources to AUR.

   Push to AUR4 using ``push.sh (git|lts) aur4``. This commits the latest
   changes to each individual package repo (for AUR) and uses ``git push`` to
   push to AUR.

.. _clean-chroot-manager: https://aur.archlinux.org/packages/clean-chroot-manager
