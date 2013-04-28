#!/bin/bash

ZFS_VER=0.6.1
LIN_VER=3.8.10
PKGREL=1

CHROOT_NAME="general"

. ../../tools/lib/lib.sh "$@"

CUR_LIN_VER=$(grep "pkgver=" spl-utils/PKGBUILD | cut -d= -f2 | cut -d_ -f2)
CUR_ZFS_VER=$(grep "pkgver=" spl-utils/PKGBUILD | cut -d= -f2 | cut -d_ -f1)
CUR_PKGREL_VER=$(grep "pkgrel=" spl-utils/PKGBUILD | cut -d= -f2)

find . -iname "PKGBUILD" -print | xargs sed \
    -i "s/$CUR_LIN_VER-$CUR_PKGREL_VER/$LIN_VER-$PKGREL/g"

find . -iname "PKGBUILD" -print | xargs sed -i \
    "s/pkgrel=$CUR_PKGREL_VER/pkgrel=$PKGREL/g"

find . -iname "PKGBUILD" -print | xargs sed -i "s/$CUR_ZFS_VER/$ZFS_VER/g"

find . -iname "PKGBUILD" -print | xargs sed -i "s/$CUR_LIN_VER/$LIN_VER/g"

for PKG in "spl-utils" "spl" "zfs-utils" "zfs"; do
    msg "Building $PKG"
    build "$PWD/$PKG"
    msg "Adding $PKG to the $REPO_PATH repository"
    add_packages_to_repo "$PWD/$PKG" "$REPO_PATH"
    msg "Moving package sources to $SOURCE_PATH"
    move_package_sources "$PWD/$PKG" "$SOURCE_PATH"
done
