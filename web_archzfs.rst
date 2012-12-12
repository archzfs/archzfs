======================================
Arch ZFS - ZFS On Linux Kernel Modules
======================================
:status: hidden
:slug: archzfs

This is the official web page of the Arch ZFS kernel modules for ZFS on Linux.
Here you can find makepkg sources for building Arch ZFS yourself, or pre-built
x86_64 packages. You can also add the unofficial repository to your
makepkg.conf and receive automatic updates. For the source to the build script
used to generate these packages, see archzfs-github_.

**Please note**, if you install these binaries, you will not be able to update
to the next kernel versions without first having available the latest compiled
ZFS package for that update. The current version of Arch ZFS, 0.6.0-rc12, can
only be used with kernel version 3.6.6. Once 3.6.7 is released, ZFS on Linux
will have to be recompiled to target 3.6.7.

For more information about the packager, Jesus Alvarez, see demizerone.com_. My
packages and database are signed by my PGP key, but my key is not signed by any
of the Arch Linux master keys, so you will have to locally sign my key and add
it to your trust, see below for more info.

My arch linux contributions
---------------------------

* `AUR - Packages`_

* `ArchWiki - Edits`_

* `bbs.archlinux.org - Posts`_ (Search for demizer)

* github_


My Unofficial Arch Linux Repository
-----------------------------------

If you are adding my repository to pacman, you will first need to un-install all
versions of zfs.

Stop any services accessing your drives, like nfs,

.. code-block:: console

    # systemctl stop nfsd.service

Then umount your ZFS filesystem,

.. code-block:: console

    # umount /mnt/data

Remove the old version of zfs,

.. code-block:: console

    # pacman -Rs zfs

Next, add the following to `/etc/pacman.conf`:

.. code-block:: bash

    [archzfs]
    SigLevel = Required DatabaseOptional TrustedOnly
    Server = http://demizerone.com/$repo/$arch

Both the database and the packages are signed, so you will have to add my key
to pacman's trusted key list.

.. code-block:: console

    # pacman-key -r 0EE7A126

verify it using the info below and then sign it with the local master key:

.. code-block:: console

    # pacman-key --lsign-key 0EE7A126

next, update your pacman database

.. code-block:: console

    # pacman -Syy

and install the package group,

.. code-block:: console

    # pacman -S zfs

Notes
-----

* My key is not signed by any of the master keys, so you will have to self sign
  it with your local master key. This page is hopefully an attempt to persuade
  you that it is legit and I mean no harm. Look below on how to verify my key.

* To read about key management in Arch, see
  `pacman-key <https://wiki.archlinux.org/index.php/Pacman-key>`_ and
  `pacman.conf <https://www.archlinux.org/pacman/pacman.conf.5.html#_package_and_database_signature_checking>`_.

My PGP Key
----------

All of my packages and package databases are signed with the following key,

0EE7A126_
~~~~~~~~~

The short version::

    pub   2048R/0EE7A126 2012-10-24
	Key fingerprint = B18A 9C9F 1E4E EAFF 072D  AB9E 5E1A BF24 0EE7 A126
    uid                  Jesus Alvarez <jeezusjr@gmail.com>
    sub   2048R/DAB97A2B 2012-10-24

and the long version::

    -----BEGIN PGP PUBLIC KEY BLOCK-----
    Version: SKS 1.1.0

    mQENBFCHi6oBCADbqiZasgwE//HtfGvyOynXapEP67tNFsKUgFR/XIVi8Io5ehCD88wOpN0O
    02u73OjDssTNh+yEN8ItixhxbZQClE7X4AG2/I49PBsPnY2G3zGPa2TB6vt5GStyVOFJjxsX
    F3sWcxfaBXSGonc9Qc8MSKmwwyvG5ASjCYYjK60UKoEqRF09DI/fMaOWcGoosNzNUntzuyAw
    9anRPZc/Chtmpd0DyQ4MhkGV18BWSsoGJsTeASo+jq98FcTKhUOfzpPccwmrQ+ViX+RIXIc/
    6WtnFs1rE0peWio3sgy+JvywT+8z2yrKZ+ovE1BQYgm2hZ4z6t55gdjfpw4uWtV4BsGzABEB
    AAG0Ikplc3VzIEFsdmFyZXogPGplZXp1c2pyQGdtYWlsLmNvbT6JATgEEwECACIFAlCHi6oC
    GwMGCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEF4avyQO56EmiKoH/iPqzt2+OycQ+tXX
    Gv2f/21dSEihGzvyXaC+yOwVrtvMamgxTeChnGi8H3gSabmTGyTJT60WsMmVtgUKZ7rqKh6b
    KbV1mIU8m/ZrzGJVrDc8JI+MrDmeaCaqTqZby+NeM5QNZ+FQiHX0dogpO3nvr3EvuipeSGu/
    KKsCfR9UxK0SwowBbfn6/3t7obO1il+eq6fHOB0+SuM6a9CssTOtPXim43VaDusaDJ13d5+3
    Ey/Mxbif5N+RzMgVavkAL5w0Cf4PElqNWA4aGfDxfhUvZ+WUOC+AFGZ/uGHwxdJLaCSx4aEI
    8CDj3trZnPit2umi64JHBb3KYLKey0duz/ztgtS5AQ0EUIeLqgEIALZx/agW3opcodJvUF7K
    4L1H9xnqw+bVBXIFyDvSCfWxLgS2MDTl/q38o62u4Htngwix8RsLEWqrtFfAi90VAxJ57pQZ
    xYZBAyEOoEOOBYJWbNxneHUSCp6+yGQiiyB0kMoCG9JMlcEmv8fwGqqardBR4+ZM2Acf+aLg
    xxi+7B3Ey7Vo/2MnzIu5GeUolDSmyDkUA91WdQByEoUWRVcRvQ+gQz/HGInHxPmqRIKFWSbg
    k1oBpCD7yJV+MfJAFaXvrEXn6jLKdIzWixIzhbVpt5RA+2wLzuTA/V5OGglNKOCWshkkjQBw
    SCOKPnYez/081Quw+1TIY8FuJY/fEv1Z1ZEAEQEAAYkBHwQYAQIACQUCUIeLqgIbDAAKCRBe
    Gr8kDuehJh47B/4myliSn3064a+a77wmvxNphuxKkUPU1gYu0aKF5bmT6nD3iOt3WA8pEcXL
    aVkA++nquTu2K8vGqZT4qBvcxP5W8s7mjVhP0h9N7VpikiAouRjEFYCVTjdwJbn0junCTjm4
    Ixr4fX5L7EgqCrToKbuQhlocwNPy1aJglm2MwDFzOFxK8R8Dx5O7xD/2b0pBdX/KHPqn2ENC
    yiKh/uUuykKpwEXVPPijL6nuA7BBacseXTn8ldAHStrhPEKnZ7mPV9j3VjlRHbYblvLGBBQi
    R6y3yNGqe7NjgJQW4e0ibvsbkG6PyUP4BLVUY6CGQFPt1p7dX4xioErHqdqPkjLzMvpi
    =TUqo
    -----END PGP PUBLIC KEY BLOCK-----

ZFS update procedure
====================

This is the procedure used to update the zfs package versions. This could be
caused by a new zfs release version or a kernel update.

1. Unmount all zfs pools

    .. code-block:: console

        # systemctl stop zfs

   If there is a problem unmounting the drive, such as "target is busy", you
   can see what process is using the mount by using fuser.

    .. code-block:: console

        # fuser /mnt/data
        # sudo fuser -v /mnt/data

                            USER        PID ACCESS COMMAND
        /mnt/data:           root     kernel mount /mnt/data

   This directory is exported by nfs, so we'll have to stop the nfs server
   before unmounting.

    .. code-block:: console

        # systemctl stop nfsd

#. Remove the old zfs version:

    .. code-block:: console

        # pacman -R archzfs

#. Update all packages and restart:

    .. code-block:: console

        # pacman -Syu
        # systemctl restart

#. Update PKGBUILD.py

   * Change ``PACKAGE_REL``

   * Change ``SOURCE_VER``

   * Update ``MD5SUMS`` with ``./build.py -m``

#. Build the new packages and repo:

    .. code-block:: console

        ./build.py -bxs split

#. Add PKGBUILD.py and archzfs/ to the index

#. Commit the changes with

    .. code-block:: console

        gc -m "Update to 0.6.0-rc12\_6-linux-3.6.9"

    Note: "\_6" is the pkgrel version.

#. Tag the commit on the master branch

    .. code-block:: console

        git tag 0.6.0-rc12\_6-linux-3.6.9 -as -m "Support for zfs-0.6.0-rc12\_6 and Kernel 3.6.9"

#. Go to the demizerone.com repo and "make publish"

#. Push the changes:

    .. code-block:: console

        git push web

#. Testing

   * Uninstall the built packages:

    .. code-block:: console

        # pacman -Rs zfs

   * Install the repo packages to test the repo:

    .. code-block:: console

        # pacman -Syy
        # pacman -S zfs

#. The entire process went very smoothly.

#. AUR COMMENT:

    The packages have been updated for kernel 3.6.7.

    If you installed the packages from AUR, you will need to first remove the zfs
    and spl packages:

        # pacman -Rsc spl-utils

    and then update the kernel:

        # pacman -S linux linux-headers

    You will now have to restart your system.

    Once your system is back up, you can proceed with building and installing zfs
    and spl, in the following order: spl-utils, spl, zfs-utils, and zfs. Then
    restart, or:

        # modprobe zfs spl

    You could also use the prebuilt signed repository available at
    http://demizerone.com/archzfs and you will not have to remove the packages,
    update the kernel, and restart before performing the update.

    Also, these new packages now have a group, 'arch-zfs'. So next time you could
    remove the packages with just:

        # pacman -R arch-zfs

    If usig the signed repository, you can now install all the packages with:

        # pacman -S arch-zfs

Git merge Arch ZFS repo_support to master and tag
=================================================
:Added: Thu Nov 15 12:52:21 PST 2012
:Tags: git, merge, tag

1. git co master

#. git tag -s 0.6.0-rc11

#. git merge --no-ff repo_support

#. I messed up and want to undo the merge

   git reset --hard 6f764ef

#. git co repo_support

#. Undo merge

   git reset --hard 3115cb5

#. git merge --no-ff 0.6.0-rc12

#. git br -d 0.6.0-rc12

#. git br -m develop repo_support

#. git co master

#. git merge --no-ff develop

#. I need to rename the old 0.6.0-rc11 tag

   git co 0.6.0-rc11
   git tag 0.6.0-rc11 0.6.0-rc11-linux-3.5.6
   git tag -d 0.6.0-rc11

#. Switch back to previous development

   git co logging_support
   git rebase develop
   git stash pop
   git reset HEAD



Building arch-zfs
=================

.. code-block:: console

    $ ./build.py -bnxs split

1. Use namcap.

#. Inspect package files

.. code-block:: console

    $ pacman -Qnp <package>

#. Add packages to repository

.. code-block:: console

    $ ./build.py -Rx

#. Remove install packages, reboot, reinstall from repository, and reboot to
   make sure they are excepted.

#. Make sure the kernel modules are loaded

.. code-block:: console

   $ lsmod | grep spl
   $ lsmod | grep zfs

Updating the repository
=======================

.. code-block:: console

    $ cd ~/projects/html/demizerone.com
    $ make publish

.. _archzfs-github: https://github.com/demizer/archzfs
.. _demizerone.com: http://demizerone.com
.. _0EE7A126: http://pgp.mit.edu:11371/pks/lookup?op=vindex&search=0x5E1ABF240EE7A126
.. _ArchWiki - Edits: https://wiki.archlinux.org/index.php/Special:Contributions/Demizer
.. _bbs.archlinux.org - Posts: https://bbs.archlinux.org/search.php
.. _AUR - Packages: https://aur.archlinux.org/packages/?O=0&C=0&SeB=m&K=demizer&outdated=&SB=n&SO=a&PP=50&do_Search=Go
.. _github: http://www.github.com/demizer
