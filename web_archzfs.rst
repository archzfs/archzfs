======================================
Arch ZFS - ZFS On Linux Kernel Modules
======================================
:Modified: Fri Jan 04 18:53:20 PST 2013
:status: hidden
:slug: archzfs

.. important:: The database path for the archzfs repository has moved. It is now
               located at "http://demizerone.com/$repo/core/$arch"! Please
               update the server lines in your pacman.conf as necessary. This
               change was necessary to add support for a testing repository.

This is the official web page of the Arch ZFS kernel module packages for native
ZFS on Linux. Here you can find pacman package sources and pre-built x86_64
packages. For effortless package installation and updates, it is possible to
add the unofficial repository to your pacman.conf. There is also a special
repository for using ZFS with the archiso install media for installing arch
onto a ZFS root filesystem, or doing emergency maintenance. To see the package
sources and repository development history, see archzfs-github_.

.. note:: The ZFS and SPL packages are depend on a specific kernel
          version. You will not be able to perform kernel updates until updated
          ZFS packages are pushed to the archzfs repository for the new kernel
          version. If you installing ZFS manually using the AUR packages, you
          would be required to first un-install ZFS, perform the kernel update,
          restart the host, and then build and install the updated AUR ZFS
          packages.

32bit support for ZFS on Linux is unstable due to inconsistencies in memory
management between the Solaris kernel and the Linux kernel. For this reason,
**the ZFS packages for Arch Linux do not yet support i686**. However, 32bit
support will be added in the future for those brave enough to face the
consequences. See `ZFS on Linux FAQ - 64bit`_

The archzfs repository and packages are signed, but the key is not trusted by
any of the Arch Linux master keys. You will have to locally sign the key and
add it to your trust. See below for more info.

For more information about the packager, Jesus Alvarez, see demizerone.com_.

------------------------------------
The archzfs un-official repositories
------------------------------------

This repository is updated on every kernel release. This allows for effortless
installation and updates.

To start, add the server information to `/etc/pacman.conf`,

.. code-block:: bash

    [archzfs]
    Server = http://demizerone.com/$repo/core/$arch

Both the database and the packages are signed, so you will have to add the
signing key to pacman's trusted key list:

.. code-block:: console

    # pacman-key -r 0EE7A126

verify it using the info below and then sign it with the local master key

.. code-block:: console

    # pacman-key --lsign-key 0EE7A126

next, update your pacman database

.. code-block:: console

    # pacman -Syy

and finally, install the package group

.. code-block:: console

    # pacman -S archzfs

.. note:: To read about key management in Arch, see pacman-key_ and
          pacman.conf_

ZFS support for testing
=======================

It is possible to use ZFS with the official Arch Linux testing repository.

.. code-block:: bash

    [archzfs]
    Server = http://demizerone.com/$repo/testing/$arch

ZFS support for archiso
=======================

If emergency maintenance is ever required on a ZFS file system from an archiso
live environment, you will need to use the archzfs repository that tracks the
current archiso release. To use it, follow the steps above for accessing the
archzfs repository, but instead use the special server line below when adding
the server information to pacman.conf:

.. code-block:: bash

    [archzfs]
    Server = http://demizerone.com/$repo/archiso/$arch

-----------------------
Signing key for archzfs
-----------------------

The ZFS packages and database are signed with the package maintainer's key. The
current maintainer is Jesus Alvarez and his key can be verified at
demizerone.com_ This key is not trusted by any of the Arch Linux Master Keys.

0EE7A126_
=========

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

--------------------
ZFS update procedure
--------------------

This is the procedure the ZFS package maintainer should use to update the ZFS
package versions on the development host. This could be provoked by a new ZFS
release version or a kernel update.

Unmount all zfs pools
=====================

.. code-block:: console

    # systemctl stop zfs

If there is a problem unmounting the drive, such as "target is busy", you can
see what process is using the mount by using fuser.

.. code-block:: console

    # fuser /mnt/data
    # sudo fuser -v /mnt/data

                        USER        PID ACCESS COMMAND
    /mnt/data:           root     kernel mount /mnt/data

This directory is exported by nfs, so we'll have to stop the nfs server before
unmounting.

.. code-block:: console

    # systemctl stop nfsd

Remove the old ZFS version
==========================

.. code-block:: console

    # pacman -R archzfs

Perform pacman update and restart
=================================

.. code-block:: console

    # pacman -Syu
    # systemctl restart

Create a new branch in git
==========================

(optional)

The new git branch should be name for the current version of the ZFS on Linux
project and the Linux Kernel version it will target.

.. code-block:: console

    $ git checkout -b zfs-0.6.0-rc12-linux-3.7.X

This branch has 'X' as the last revision number because when a minor point
release kernel is released, such as 3.7, it can take a while for it to move
into the [core] repository. The 3.7 kernel can remain in testing for multiple
revisions.

Update the ZFS PKGBUILDs
========================

1. Change ``pkgrel``.

#. Change the kernel versions to the targeted kernel version.

#. Update ``md5sums`` with ``makepkg -g``.

   This step is only necessary if the upstream ZFS version has changed. If this
   is the case, the ``pkgrel`` should also be changed to ``1``.

Building archzfs
================

Go into each package directory in order: spl-utils, spl, zfs-utils, zfs and use
makepkg to build the packages:

.. code-block:: console

    $ makepkg -sfic

.. note:: If either SPL or ZFS do not build due to kernel incompatibilities,
          patches will be needed to allow building to continue. See `Patching
          ZFS`_.

Start the ZFS service
---------------------

This step is not necessary if you are using ZFS as root.

.. code-block:: console

    # systemctl daemon-reload
    # zpool import -a
    # systemctl start zfs

Add packages to repository
--------------------------

This is done using the ``repo_add.py`` python script for efficiency. It can be
found `here <https://github.com/demizer/binfiles>`_.

.. code-block:: console

    $ repo_add.py -r archzfs -v rc12-9

Testing
-------

Reboot to make sure the ZFS packages are used after a system boot and the
systemd file is in working order. Also sync the updates to other local systems
to make sure the updated packages are picked up by pacman and install properly.

Commit changes to git
---------------------

Add PKGBUILD.py and archzfs/ to the index and commit the changes with

.. code-block:: console

    git commit -m "Update to ZFS version 0.6.0-rc12-8 and linux-3.7"

.. note:: "-8" at the end of the ZFS version is the pkgrel.

Now tag the commit on the master branch

.. code-block:: console

    git tag 0.6.0-rc12\_6-linux-3.6.9 -as -m "Support for zfs-0.6.0-rc12\_6 and Kernel 3.6.9"

Update the webpage
==================

Open the command terminal and cd to the webpage repository powered by Pelican.
Use make to generate the updated website:

.. code-block:: console

    make publish

then push the changes with rsync,

.. code-block:: console

    ./push_archzfs.sh -n

'-n' is used to verify the files being pushed are correct. Once that is done,
re-use the command without the dry-run argument.

Anoucement template
===================

AUR
---

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

.. _Patching ZFS:

Creating a patch for ZFS
========================

On some occasions, a new kernel version is pushed to the [core] repository
that the latest ZFS on Linux release does not build against. The biggest
problem with this is that the master branch of the ZFS on Linux repository
already contains the required build fixes, but the next release could be weeks
away, causing the packages in AUR to be flagged out of date for that period of
time.

The goal of this section is to document the procedure for creating a patch to
bring the release version up-to-date with the latest kernel so that the AUR
packages do not remain out of date. Otherwise, the user would have to
un-install the current AUR packages and install special 'zfs-git' packages
until the next ZFS on Linux release is made and then switch back to the
standard ZFS AUR packages.

.. note:: The ZFS and SPL projects track each other. If either package requires
          a patch, then both projects should be patched. Each project is split
          into two packages for Arch Linux so the patch must be applied to both
          packages for each project.

.. code-block:: console

    $ git clone https://github.com/zfsonlinux/zfs.git

Once the repository is cloned, create a branch.

.. code-block:: console

    $ git checkout -b archzfs_patch

Revert the head to the last release.

.. code-block:: console

    $ git reset --hard <commit>

Merge the master branch into the archzfs_patch branch.

.. code-block:: console

    $ git merge --squash master

Finally, generate the new patch.

.. code-block:: console

    $ git diff --cached > ../linux-3.7.patch

.. _archzfs-github: https://github.com/demizer/archzfs
.. _demizerone.com: http://demizerone.com
.. _0EE7A126: http://pgp.mit.edu:11371/pks/lookup?op=vindex&search=0x5E1ABF240EE7A126
.. _pacman-key: https://wiki.archlinux.org/index.php/Pacman-key
.. _pacman.conf: https://www.archlinux.org/pacman/pacman.conf.5.html#_package_and_database_signature_checking
.. _ZFS on Linux FAQ - 64bit: http://zfsonlinux.org/faq.html#WhyShouldIUseA64BitSystem
