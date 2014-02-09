Zettabyte File System for Arch Linux
====================================

Homepage: http://demizerone.com/archzfs

These are the sources and packages for the ZFS filesystem support for Arch
Linux.

This repository contains the pacman package sources, pre-built packages, pacman
package repository, and documentation.

--------
Licenses
--------

The license of the Arch Linux package sources is MIT.

The license of ZFS is CDDL.

The license of SPL is LGPL.

--------------------------
How to use this Repository
--------------------------

.. note:: All of these commands require the current directory to be the archzfs
          project directory.

1. Set the appropriate variables in conf.sh

   * Repository base path

     The parent directory of the `demz-repo-core` and `demz-repo-archiso` repos.

   * GPG signing key

     Used to sign the packages and repo database.

   * Your email address

     Used for reporting changes changes in `scraper.sh`. Mutt and msmtp are
     used for sending email. Required only if `scraper.sh` or `verifier.sh` are
     going to be used.

   * Ssh remote login

     Used in `verifier.sh` for making sure the local `demz-repo-*` are in sync
     with the remote repos.

#. Set the appropriate kernel versions in conf.sh.

   If the any of the `*_X*_PKGREL` variables are changed in `conf.sh`, then
   `AZB_PKGREL` must be incremented as well. `AZB_PKGREL` controls the top
   level `pkgrel` inside the PKGBUILDS.

#. Update the PKGBUILDs

   Use `./build update` to update the PKGBUILDS using the `conf.sh` variables.

   `./build.sh update test` uses the `AZB_LINUX_TEST_*` variables. Using the
   test values are useful for test building the zfs packages against the Linux
   kernel version in the official testing repo. Mostly used on minor Linux
   kernel updates (3.12 -> 3.13).

#. Build the packages

   Use `./build.sh make -u` to build the packages, update the clean chroot in
   the process.

   It is possible to use `./build.sh update make -u` in one shot.

   If you want to see command output only, use `./build.sh make -n`. Add the
   `-d` to see debugging output.

#. Add packages to the repo

   Use `./repo.sh core -n` to what changes will occur without actually making
   them.

   `./repo.sh core` will add the package versions defined by
   `AZB_LINUX_VERSION` to the `demz-repo-core` repository.

#. Push the package sources to AUR.

   Pushing to AUR using `push.sh` requires `burp <https://www.archlinux.org/packages/extra/x86_64/burp/>`.
   Simply use `./push.sh` to push the package source version (specified by
   `AZB_LINUX_VERSION`) to AUR.
