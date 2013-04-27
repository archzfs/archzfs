======================================
Arch ZFS - ZFS On Linux Kernel Modules
======================================
:Modified: Fri Apr 26 21:13:37 PDT 2013
:status: hidden

.. important:: The archzfs packages are now hosed in the demz-repo-core
               repository and is located at
               "http://demizerone.com/$repo/$arch". Please update the server
               lines in your pacman.conf as necessary.

This is the official web page of the Arch ZFS kernel module packages for native
ZFS on Linux. Here you can find pacman package sources and pre-built x86_64 and
i686 packages. For effortless package installation and updates, it is possible
to add the unofficial repository to your pacman.conf. There is also a special
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
management between the Solaris kernel and the Linux kernel. See `ZFS on Linux
FAQ - 64bit`_ However, users have reported on the AUR ZFS page of running ZFS
with compiled 32bit packages without any problems. For this reason, ZFS on Arch
Linux does support i686.

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

    [demz-repo-core]  # For zfs packages
    Server = http://demizerone.com/$repo/$arch

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

    [demz-repo-testing]  # For zfs packages
    Server = http://demizerone.com/$repo/$arch

ZFS support for archiso
=======================

If emergency maintenance is ever required on a ZFS file system from an archiso
live environment, you will need to use the archzfs repository that tracks the
current archiso release. To use it, follow the steps above for accessing the
archzfs repository, but instead use the special server line below when adding
the server information to pacman.conf:

.. code-block:: bash

    [demz-repo-archiso]
    Server = http://demizerone.com/$repo/$arch

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

Create a new branch in git (optional)
=====================================

The new git branch should be name for the current version of the ZFS on Linux
project and the Linux Kernel version it will target.

.. code-block:: console

    $ git checkout -b zfs-0.6.1_3.7.X

This branch has 'X' as the last revision number because when a minor point
release kernel is released, such as 3.7, it can take a while for it to move
into the [core] repository. The 3.7 kernel can remain in testing for multiple
revisions.

Building the packages
=====================

Building the packages requires that the devtools_ package be installed. This
section assumes the host system is of x86_64 architecture.

update.sh builds i686 and x86_64 packages in a clean chroot environment. This
method requires 5-10GB of space and some setup time in order to work properly.
The size is largely determined by the number of chroots you have. On my system
I have four copies and two root copies, totaling 13GB.

Creating the chroot environment
-------------------------------

The steps below outline the creation of the of the chroot root copy that a
clean chroot is made from using rsync. This root environment is only used as a
pristine copy, no packages are installed or built inside the root copy.

You can adjust the variables used by pbldr when working with chroot
environments with the config.json configuration file in the project root
directory, or you can pass them as arguments to the script.

32bit chroot environment
~~~~~~~~~~~~~~~~~~~~~~~~

See `Buldinig 32-bit packages on a 64-bit system`_ for more information. While
this wiki article can be used as a reference, the pbldr tool expects the
directory structure defined in the following code block.

.. code-block:: console

    # mkdir -p /opt/chroot/{i686,x86_64}
    # setarch i686 mkarchroot -C "/usr/share/devtools/pacman-extra.conf" \
      -M "/usr/share/devtools/makepkg-i686.conf" /opt/chroot/i686 base base-devel sudo

Edit pacman.conf and makepkg.conf and adjust to your desire. Specifically, the
packager and host fields.

.. code-block:: console

    # vim /opt/chroot/i686/root/etc/makepkg.conf \
      /opt/chroot/i686/root/etc/pacman.conf

It is necessary to periodically perform updates to the chroot root copy, to do
this, you will have to chroot into the root copy and perform the update. This
same method is used to install new packages in the root copy.

.. code-block:: console

    # linux32 arch-chroot /opt/chroot/i686/root /bin/bash
    # pacman -Syu
    # pacman -S <package>
    # exit

64bit chroot environment
~~~~~~~~~~~~~~~~~~~~~~~~

The procedure for creating the 64bit chroot root environment is nearly
identical to the commands used to create the 32bit chroot environment.

.. code-block:: console

    # mkarchroot -C "/usr/share/devtools/pacman-multilib.conf" \
      -M "/usr/share/devtools/makepkg-x86_64.conf" /opt/chroot/x86_64 base \
      multilib-devel sudo

Edit pacman.conf and makepkg.conf and adjust to your desire. Specifically, the
packager and host fields.

.. code-block:: console

    # vim /opt/chroot/x86_64/root/etc/makepkg.conf /opt/chroot/x86_64/root/etc/pacman.conf

Periodically it is necessary to perform updates to the chroot root copy, to do
this, you will have to chroot into the root copy and perform the update. This
is the same method used to install new packages in the root copy.

.. code-block:: console

    # arch-chroot /opt/chroot/x86_64/root /bin/bash
    # pacman -Syu
    # pacman -S <package>
    # exit

Build the packages
------------------

The specially made update script will automatically replace the version string
with the new one and also add the built packages to the repo. To change the
paths of the script, edit it and update the variables.

.. code-block:: console

    # ./update.sh -k 3.8.8 -p 2 -t core

This command will build i686 and x86_64 packages in a clean chroot copy.

Once the packages are added to the repo, sync the databases using pacman and
update or install archzfs.

.. code-block:: console

    # pacman -Sy archzfs

Start the ZFS service
=====================

This step is not necessary if you are using ZFS as root.

.. code-block:: console

    # systemctl daemon-reload
    # zpool import -a
    # systemctl start zfs

Commit changes to git
=====================

Add PKGBUILD.py and archzfs/ to the index and commit the changes with

.. code-block:: console

    $ git commit -m "Update core to 0.6.1_3.8.8-2"

.. note:: "-2" at the end of the ZFS version is the pkgrel.

Update the webpage
==================

The webpage is a simple restructured text file. To regenerate it, I use a
script that also pushes the repository to the website.

.. code-block:: console

    $ ./push_demz_repos -n

'-n' is used to verify the files being pushed are correct. Once that is done,
re-use the command without the dry-run argument.

The script can be found here: https://github.com/demizer/binfiles/blob/master/push_demz_repos.sh

.. _archzfs-github: https://github.com/demizer/archzfs
.. _demizerone.com: http://demizerone.com
.. _0EE7A126: http://pgp.mit.edu:11371/pks/lookup?op=vindex&search=0x5E1ABF240EE7A126
.. _pacman-key: https://wiki.archlinux.org/index.php/Pacman-key
.. _pacman.conf: https://www.archlinux.org/pacman/pacman.conf.5.html#_package_and_database_signature_checking
.. _ZFS on Linux FAQ - 64bit: http://zfsonlinux.org/faq.html#WhyShouldIUseA64BitSystem
.. _devtools: https://www.archlinux.org/packages/extra/any/devtools
.. _Buldinig 32-bit packages on a 64-bit system: https://wiki.archlinux.org/index.php/Building_32-bit_packages_on_a_64-bit_system
