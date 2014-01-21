#!/bin/bash
#
# This script builds the archzfs packages in a clean clean chroot environment.
#
# For debug output, use DEBUG=1 ./build.sh

# Defaults, don't edit these.
PKG_LIST="spl-utils spl zfs-utils zfs"
UPDATE_PKGBUILDS=""
BUILD=0
CHROOT_CLEAN=""
CHROOT_UPDATE=""
CHROOT_TARGET=""
SIGN=""
CLEANUP=0

source ./lib.sh
source ./conf.sh

set -e

usage() {
	echo "build.sh - A build script for archzfs"
    echo
	echo "Usage: $0 [-C] [<chroot> [options]]"
    echo
    echo "  build.sh -C                 :: Remove all compiled packages"
    echo "  build.sh update             :: Update PKGBUILDS"
    echo "  build.sh core -u            :: Update and build in core chroot"
    echo "  build.sh test               :: Build in test chroot"
    echo "  build.sh update core -u -c  :: Update PKGBUILDs, Update, clean,"
}

sed_escape_input_string() {
    echo "$1" | sed -e 's/[]\/$*.^|[]/\\&/g'
}

build() {
    # $1: List of dependencies to install
    sudo bash $PWD/builder
    rm $PWD/builder
}

build_sources() {
    for PKG in $PKG_LIST; do
        cd "$PWD/$PKG"
        msg2 "Building source for $PKG";
        makepkg -Sfc
        cd - > /dev/null
    done
}

sign_packages() {
    FILES=$(find $PWD -iname "*${ZOL_VERSION}_${LINUX_VERSION}-${PKGREL}*.pkg.tar.xz")
    echo $FILES
    for F in $FILES; do
        msg2 "Signing $F"
        gpg --batch --yes --detach-sign --use-agent -u $GPG_SIGN_KEY "$F" # &>/dev/null
    done

}

cleanup() {
    find . \( -iname "*.log" -o -iname "sed*" \) -exec rm {} \;
}

update_pkgbuilds() {
    CUR_ZFS_VER=$(grep "pkgver=" zfs/PKGBUILD | cut -d= -f2 | cut -d_ -f1)
    CUR_PKGREL_VER=$(grep "pkgrel=" zfs/PKGBUILD | cut -d= -f2)
    CUR_LINUX_VER=$(grep "linux=" zfs/PKGBUILD | sed -r "s/.*linux=(.*)-.+/\1/g")
    CUR_LINUX_PKGREL=$(grep "linux=" zfs/PKGBUILD | sed -r "s/.*linux=.+-(.+)\"\)/\1/g")

    SED_CUR_LIN_VER=$(sed_escape_input_string $CUR_LINUX_VER)
    SED_CUR_ZFS_VER=$(sed_escape_input_string $CUR_ZFS_VER)

    CUR_DEPEND_VER=${CUR_ZFS_VER}_${CUR_LINUX_VER}-$CUR_PKGREL_VER
    NEW_DEPEND_VER=${ZOL_VERSION}_${LINUX_VERSION}-$PKGREL

    debug "ZOL_VERSION: ${ZOL_VERSION}"
    debug "LINUX_VERSION: ${LINUX_VERSION}"
    debug "CUR_ZFS_VER: $CUR_ZFS_VER"
    debug "CUR_PKGREL_VER: $CUR_PKGREL_VER"
    debug "CUR_LINUX_VER: $CUR_LINUX_VER"
    debug "CUR_LINUX_PKGREL: $CUR_LINUX_PKGREL"
    debug "SED_CUR_LIN_VER: $SED_CUR_LIN_VER"
    debug "SED_CUR_ZFS_VER: $SED_CUR_ZFS_VER"
    debug "CUR_DEPEND_VER: $CUR_DEPEND_VER"
    debug "NEW_DEPEND_VER: $NEW_DEPEND_VER"

    # Change the top level PKGREL
    find . -iname "PKGBUILD" -print | xargs sed -i \
        "s/pkgrel=$CUR_PKGREL_VER/pkgrel=$PKGREL/g"

    # Change the spl version number in zfs/PKGBUILD
    sed -i "s/$CUR_DEPEND_VER/$NEW_DEPEND_VER/g" zfs/PKGBUILD

    # Replace the ZFS version
    find . -iname "PKGBUILD" -print | xargs sed -i \
        "s/$SED_CUR_ZFS_VER/$ZOL_VERSION/g"

    # Replace the linux version, notice "="
    find . -iname "PKGBUILD" -print | xargs sed -i \
        "s/=$SED_CUR_LIN_VER-$CUR_LINUX_PKGREL/=$LINUX_VERSION-$LINUX_PKGREL/g"

    # Replace the linux version in the top level VERSION
    find . -iname "PKGBUILD" -print | xargs sed -i \
        "s/_$SED_CUR_LIN_VER/_$LINUX_VERSION/g"

    # Update the sums of the files
    for PKG in $PKG_LIST; do
        updpkgsums $PKG/PKGBUILD
    done

}

if [ $# -lt 1 ]; then
    usage;
    exit 0;
fi

ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "test" || ${ARGS[$a]} == "core" ]]; then
        BUILD=1
        CHROOT_TARGET=${ARGS[$a]}
    elif [[ ${ARGS[$a]} == "update" ]]; then
        UPDATE_PKGBUILDS=1
    elif [[ ${ARGS[$a]} == "sign" ]]; then
        SIGN=1
    elif [[ ${ARGS[$a]} == "-u" ]]; then
        CHROOT_UPDATE="-u"
    elif [[ ${ARGS[$a]} == "-c" ]]; then
        CHROOT_CLEAN="-c"
    elif [[ ${ARGS[$a]} == "-C" ]]; then
        CLEANUP=1
    fi
done

if [[ $UPDATE_PKGBUILDS == 1 ]]; then
    update_pkgbuilds
fi

if [[ $SIGN == 1 ]]; then
    sign_packages
fi

if [[ $BUILD == 1 ]]; then
    build
    build_sources
    sign_packages
fi

if [[ $CLEANUP == 1 ]]; then
    msg2 "Cleaning up work files..."
    find . \( -iname "sed*" -o -iname "*.log" -o -iname "*.pkg.tar.xz*" \
        -o -iname "*.src.tar.gz" \) -print -exec rm -f {} \;
fi
