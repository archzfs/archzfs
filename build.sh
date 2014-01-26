#!/bin/bash
#
# This script builds the archzfs packages in a clean clean chroot environment.
#
# For debug output, use DEBUG=1
# To show command output, but not do anything, use DRY_RUN=1
#
# This script requires clean-chroot-manager (https://github.com/graysky2/clean-chroot-manager)

# Defaults, don't edit these.
AZB_PKG_LIST="spl-utils spl zfs-utils zfs"
AZB_UPDATE_PKGBUILDS=""
AZB_BUILD=0
AZB_CHROOT_UPDATE=""
AZB_SIGN=""
AZB_CLEANUP=0

source ./lib.sh
source ./conf.sh

set -e

trap 'trap_abort' INT QUIT TERM HUP
trap 'trap_exit' EXIT

usage() {
	echo "build.sh - A build script for archzfs"
    echo
	echo "Usage: $0 [-C] [<chroot> [options]]"
    echo
    echo "    build.sh make -u          :: Update the chroot and build all of the packages"
    echo "    build.sh -C               :: Remove all compiled packages"
    echo "    build.sh update           :: Update PKGBUILDS only"
    echo "    build.sh update make -u   :: Update PKGBUILDs, update the chroot, and make all of the packages"
    echo
    echo "Variables:"
    echo
    echo "    DEBUG=1   :: Show debug output."
    echo "    DRY_RUN=1 :: Show commands, but don\'t do anything. "
}

sed_escape_input_string() {
    echo "$1" | sed -e 's/[]\/$*.^|[]/\\&/g'
}

build_sources() {
    for PKG in $AZB_PKG_LIST; do
        msg "Building source for $PKG";
        run_cmd "cd \"$PWD/$PKG\""
        run_cmd "makepkg -Sfc"
        run_cmd "cd - > /dev/null"
    done
}

sign_packages() {
    FILES=$(find $PWD -iname "*${AZB_ZOL_VERSION}_${AZB_LINUX_VERSION}-${AZB_PKGREL}*.pkg.tar.xz")
    msg "Signing the packages with GPG"
    for F in $FILES; do
        msg2 "Signing $F"
        run_cmd "gpg --batch --yes --detach-sign --use-agent -u $AZB_GPG_SIGN_KEY \"$F\" &>/dev/null"
    done
}

update_pkgbuilds() {
    AZB_CUR_ZFS_VER=$(grep "pkgver=" zfs/PKGBUILD | cut -d= -f2 | cut -d_ -f1)
    AZB_CUR_PKGREL_VER=$(grep "pkgrel=" zfs/PKGBUILD | cut -d= -f2)
    AZB_CUR_LINUX_VER=$(grep "linux=" zfs/PKGBUILD | sed -r "s/.*linux=(.*)-.+/\1/g")
    AZB_CUR_LINUX_PKGREL=$(grep "linux=" zfs/PKGBUILD | sed -r "s/.*linux=.+-(.+)\"\)/\1/g")

    AZB_SED_CUR_LIN_VER=$(sed_escape_input_string $AZB_CUR_LINUX_VER)
    AZB_SED_CUR_ZFS_VER=$(sed_escape_input_string $AZB_CUR_ZFS_VER)

    AZB_CUR_DEPEND_VER=${AZB_CUR_ZFS_VER}_${AZB_CUR_LINUX_VER}-$AZB_CUR_PKGREL_VER
    AZB_NEW_DEPEND_VER=${AZB_ZOL_VERSION}_${AZB_LINUX_VERSION}-$AZB_PKGREL

    debug "AZB_ZOL_VERSION: ${AZB_ZOL_VERSION}"
    debug "AZB_LINUX_VERSION: ${AZB_LINUX_VERSION}"
    debug "AZB_CUR_ZFS_VER: $AZB_CUR_ZFS_VER"
    debug "AZB_CUR_PKGREL_VER: $AZB_CUR_PKGREL_VER"
    debug "AZB_CUR_LINUX_VER: $AZB_CUR_LINUX_VER"
    debug "AZB_CUR_LINUX_PKGREL: $AZB_CUR_LINUX_PKGREL"
    debug "AZB_SED_CUR_LIN_VER: $AZB_SED_CUR_LIN_VER"
    debug "AZB_SED_CUR_ZFS_VER: $AZB_SED_CUR_ZFS_VER"
    debug "AZB_CUR_DEPEND_VER: $AZB_CUR_DEPEND_VER"
    debug "AZB_NEW_DEPEND_VER: $AZB_NEW_DEPEND_VER"

    # Change the top level AZB_PKGREL
    run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/pkgrel=$AZB_CUR_PKGREL_VER/pkgrel=$AZB_PKGREL/g\""

    # Change the spl version number in zfs/PKGBUILD
    run_cmd "sed -i \"s/$AZB_CUR_DEPEND_VER/$AZB_NEW_DEPEND_VER/g\" \
        zfs/PKGBUILD"

    # Replace the ZFS version
    run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/$AZB_SED_CUR_ZFS_VER/$AZB_ZOL_VERSION/g\""

    # Replace the linux version, notice "="
    run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/=$AZB_SED_CUR_LIN_VER-$AZB_CUR_LINUX_PKGREL/=$AZB_LINUX_VERSION-$AZB_LINUX_PKGREL/g\""

    # Replace the linux version in the top level VERSION
    run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/_$AZB_SED_CUR_LIN_VER/_$AZB_LINUX_VERSION/g\""

    # Update the sums of the files
    for PKG in $AZB_PKG_LIST; do
        run_cmd "updpkgsums $PKG/PKGBUILD"
    done
}

if [ $# -lt 1 ]; then
    usage;
    exit 0;
fi

ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "make" ]]; then
        AZB_BUILD=1
    elif [[ ${ARGS[$a]} == "update" ]]; then
        AZB_UPDATE_PKGBUILDS=1
    elif [[ ${ARGS[$a]} == "sign" ]]; then
        AZB_SIGN=1
    elif [[ ${ARGS[$a]} == "-u" ]]; then
        AZB_CHROOT_UPDATE="-u"
    elif [[ ${ARGS[$a]} == "-C" ]]; then
        AZB_CLEANUP=1
    fi
done

if [[ $AZB_UPDATE_PKGBUILDS == 1 ]]; then
    update_pkgbuilds
fi

if [[ $AZB_SIGN == 1 ]]; then
    sign_packages
fi

if [[ $AZB_BUILD == 1 ]]; then
    if [ -n "$AZB_CHROOT_UPDATE" ]; then
        msg "Updating the i686 and x86_64 clean chroots..."
        run_cmd "sudo ccm32 u"
        run_cmd "sudo ccm64 u"
    fi
    for PKG in $AZB_PKG_LIST; do
        msg "Building $PKG..."
        run_cmd "cd \"$PWD/$PKG\""
        run_cmd "sudo ccm32 s"
        run_cmd "sudo ccm64 s"
        run_cmd "cd - > /dev/null"
    done
    build_sources
    sign_packages
fi

if [[ $AZB_CLEANUP == 1 ]]; then
    msg "Cleaning up work files..."
    run_cmd "find . \( -iname \"*.log\" -o -iname \"*.pkg.tar.xz*\" -o -iname \"*.src.tar.gz\" -o -iname \"src\" \) -print -exec rm -rf {} \\;"
fi
