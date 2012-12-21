======================================
Arch ZFS - ZFS On Linux Kernel Modules
======================================
:Modified: Fri Dec 21 01:58:37 PST 2012
:status: hidden
:slug: archzfs

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

---------------------
Insalling ZFS on ROOT
---------------------

https://github.com/dajhorn/pkg-zfs/wiki/HOWTO-install-Ubuntu-to-a-Native-ZFS-Root-Filesystem
ZFS Cheatsheet: http://lildude.co.uk/zfs-cheatsheet

1. Create live usb for UEFI: https://wiki.archlinux.org/index.php/UEFI#Create_UEFI_bootable_USB_from_ISO

#. Boot from live usb.

#. Use cgdisk and create a GPT partition table

   Part     Size    Type
   ====     =====  =============
      1     512M   EFI (ef00)
      2     512M   Ext4 (8200)
      2     117G   Solaris Root (bf00)

   Note the EFI partion will contain the kernel images

#. Format the EFI partion fat32

   mkfs.vfat -F 32 /dev/sda1 -n EFIBOOT

#. Format the Ext4 boot partition

   mkfs.ext4 /dev/sda2 -L BOOT

#. Check /etc/pacman.d/mirrorlist and make sure the mirrors are agreeable.

#. Add the archzfs repo to pacman.conf

    [archzfs]
    SigLevel = Required DatabaseOptional TrustedOnly
    Server = http://demizerone.com/$repo/$arch

#. Connect to the internet

   wifi-menu

#. Install archzfs key

   pacman-key -r 0EE7A126
   pacman-key --lsign-key 0EE7A126

#. Update pacman

   pacman -Syy

#. Install zfs

   pacman -S archzfs

#. Load the modules

   modprobe zfs

#. Create zfs pool

    # zpool create rpool /dev/disk/by-id/<id>

   Always use id names when working with zfs, otherwise import errors will
   occur.

#. Create zfs file systems

    Create the root filesystem

    # zfs create rpool/ROOT

    create the decendent file system that will hold the installation:

    # zfs create rpool/ROOT/arch

    We will set the mountpoints after we have created the filesystems so that
    they are not mounted automatically to occupied directories causing errors.

    Note: If you like you can create sub-filesystem mount points here such as
    /home and /root by doing the following:

    # zfs create rpool/HOME
    # zfs create rpool/HOME/root

#. Umount all zfs filesystems

    # zfs umount -a

#. Set the mount point for the decendent root filesystem

    # zfs set mountpoint=/ rpool/ROOT/arch

    optionally,

    # zfs set mountpoint=/home rpool/HOME
    # zfs set mountpoint=/root rpool/HOME/root

#. Set the bootfs property on the decendent root filesystem so the bootloader
   knows where to find the operating system.

    # zpool set bootfs=rpool/ROOT/arch rpool

#. Export the pool

    # zpool export rpool

    Don't skip this, otherwise you will be required to use -f when importing
    your pools. This unloads the imported pool.

    Note: Ubuntu help says if this command isn't used, the system will be in an
    incossistant state. The docs say that this allows the pools to be shared
    accross systems. Is this why I had to use -f when creating the pools the
    last time?

#. Re-import the pool

    # zpool import -d /dev/disk/by-id -R /mnt rpool

    Note: -d is not the actual device id, but the by-id directory containing
    the symlinks.

    If there is an error in this step, you can export the pool to redo the
    command:

    # zpool export rpool

#. Mount the EFI and boot partition

   mkdir /mnt/boot
   mount /dev/sda2 /mnt/boot
   mkdir /mnt/boot/efi
   mount /dev/sda1 /mnt/boot/efi

#. Install base packages

   pacstrap -i /mnt base base-devel archzfs

#. Generate the fstab

    # genfstab -U -p /mnt >> /mnt/etc/fstab

#. Open fstab to edit contents

    # nano /mnt/etc/fstab

   Delete all the lines except for the boot partion. ZFS auto mounts it's own
   partitions.

#. Load the efivars module

   modprobe efivars

#. Chroot into the installation

   arch-chroot /mnt /bin/bash

# Install a real text editor

    # pacman -S vim

#. Follow https://wiki.archlinux.org/index.php/Beginners%27_Guide from the
   Locale section to the Configure Pacman Section

#. Edit pacman.conf and add the archzfs repository. If on arch64, uncomment the
   multilib repo.

#. Update the pacman database

   pacman -Syy

#. Create the initramfs, edit mkinitcpio.conf and add zfs before filesystems.
   Remove fsck and then regen the initramfs:

    mkinitcpio -p linux

#. Set root passwd and add a regular user.

#. Install UEFI boot loader

   Continuing from the EFISTUB section at
   https://wiki.archlinux.org/index.php/Beginners'_Guide#Chroot_and_configure_the_base_system

    # mkdir /boot/efi
    # modprobe efivars
    # arch-chroot /mnt /bin/bash
    # mkdir -p /boot/efi/EFI/arch
    # cp /boot/vmlinuz-linux /boot/efi/EFI/arch/vmlinuz-arch.efi
    # cp /boot/initramfs-linux.img /boot/efi/EFI/arch/initramfs-arch.img
    # cp /boot/initramfs-linux-fallback.img /boot/efi/EFI/arch/initramfs-arch-fallback.img

    The images will need to be recopied everytime there is an update, see
    https://wiki.archlinux.org/index.php/Beginners'_Guide#EFISTUB for more
    information.

#. Install rEFInd

    # pacman -S refind-efi efibootmgr
    # mkdir -p /boot/efi/EFI/refind
    # cp /usr/lib/refind/refindx64.efi /boot/efi/EFI/refind/refindx64.efi
    # cp /usr/lib/refind/config/refind.conf /boot/efi/EFI/refind/refind.conf
    # cp -r /usr/share/refind/icons /boot/efi/EFI/refind/icons

    # nano /boot/efi/EFI/arch/refind_linux.conf
    "Boot to X"          "root=PARTUUID=<id> zfs=bootfs ro rootfstype=ext4 systemd.unit=graphical.target"
    "Boot to Console"    "root=PARTUUID=<id> zfs=bootfs ro rootfstype=ext4 systemd.unit=multi-user.target"

#. Add rEFInd to the UEFI boot menu

    # efibootmgr -c -g -d /dev/sdX -p Y -w -L "rEFInd" -l '\EFI\refind\refindx64.efi'

    Note: In the above command, X and Y denote the drive and partition of the
    UEFISYS partition. For example, in /dev/sdc5, X is "c" and Y is "5".

    To delete an existing boot menu item,

    # efibootmgr

    Lists the menu items and

    # efibootmgr -b D -B

    deletes.

#. Unmount and restart

    # exit
    # umount /mnt/boot
    # zfs umount -a
    # zpool export rpool
    # reboot

Emergency chroot repair with archzfs
====================================

Here is how to use the archiso to get into your ZFS filesystem.

1. Boot the latest archiso.

#. Bring up your network

   wifi-menu

   or

   ip link set eth0 up

#. Test network

   ping google.com

#. Sync pacman package database

   pacman -Syy

#. (optional) Install a better text editor:

   pacman -S vim

#. Add archzfs archiso repository to pacman.conf

   [archzfs]
   SigLevel = Required DatabaseOptional TrustedOnly
   Server = http://demizerone.com/$repo/archiso/$arch/

#. Sync the pacman package database

   pacman -Syy

#. Install archzfs

   pacman -S archzfs

#. Load the kernel modules

   modprobe zfs

#. Import your pool

   zpool import -a -R /mnt

#. Mount your boot partitions (if you have them)

   mount /dev/sda2 /mnt/boot
   mount /dev/sda1 /mnt/boot/efi

#. Chroot into your zfs filesystem

   arch-chroot /mnt /bin/bash

#. Check your kernel version

   pacman -Qi linux
   uname -r

   uname will show the kernel version of the archiso. If they are different,
   you will need to run depmod (in the chroot) with the correct kernel version
   of your chroot installation:

   depmod -a 3.6.9-1-ARCH (version gathered from pacman -Qi linux)

   This will load the correct kernel modules for the kernel version installed
   in your chroot installation.

#. Regenerate your ramdisk

   mkinitcpio -p linux

   There should be no errors.

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
