#!/bin/bash
#
# This script builds the archzfs packages in a clean clean chroot environment.
#

# Defaults, don't edit these.
PKG_LIST="spl-utils spl zfs-utils zfs"
UPDATE_PKGBUILDS=""
BUILD=0
CHROOT_CLEAN=""
CHROOT_UPDATE=""
CHROOT_TARGET=""
SIGN=""
CLEANUP=0

source "lib.sh"
source "conf.sh"

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
    cat > "$PWD/builder" <<EOF
set -e

msg() {
	local mesg=\$1; shift
	printf "${GREEN}==>${ALL_OFF}${BOLD} \${mesg}${ALL_OFF}\n" "\$@" >&2
}

package_install_list() {
    # \$1: A list of packages to install
    # \$2: The arch of the package
    for PKG in \$1; do
        FPKG=\$(find \"$REPO_BASEPATH\" -type f \
                -regex ".*\$2/\$PKG.*\\(\$2\\|any\\).pkg.tar.xz")
        PLIST+="-I \$FPKG "
    done
    \$PLIST
}

CHROOT_CLEAN="$CHROOT_CLEAN"
CHROOT_UPDATE="$CHROOT_UPDATE"
for PKG in $PKG_LIST; do
    cd "$PWD/\$PKG"
    msg "Building \$PKG";
    pkgname=\$(grep "pkgname=" PKGBUILD | sed -e "s/pkgname=([\\'\\"]\\(.*\\)[\\'\\"])/\\1/")
    for ARCH in "i686" "x86_64"; do
        if [ -n "\$CHROOT_UPDATE" ]; then
            setarch \$ARCH arch-nspawn $CHROOT_PATH/\$ARCH/$CHROOT_TARGET/root pacman -Syu --noconfirm
        fi
        I_PKGS=\$(package_install_list "$1" \$ARCH)
        ARGS="\$CHROOT_CLEAN $I_PKGS -r $CHROOT_PATH/\$ARCH/$CHROOT_TARGET -l $CHROOT_COPYNAME"
        setarch \$ARCH makechrootpkg \$ARGS -- -i
    done
    # We only need to clean once, otherwise on the update all of the package
    # updates would be installed.
    CHROOT_CLEAN=
    CHROOT_UPDATE=
    cd - > /dev/null
done
EOF
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
    CUR_ZFS_VER=$(grep "pkgver=" spl-utils/PKGBUILD | cut -d= -f2 | cut -d_ -f1)
    CUR_PKGREL_VER=$(grep "pkgrel=" spl-utils/PKGBUILD | cut -d= -f2)
    CUR_LINUX_VER=$(grep "linux=" spl-utils/PKGBUILD | sed -r "s/.*linux=(.*)-.+/\1/g")
    CUR_LINUX_PKGREL=$(grep "linux=" spl-utils/PKGBUILD | sed -r "s/.*linux=.+-(.+)\"\)/\1/g")

    SED_CUR_LIN_VER=$(sed_escape_input_string $CUR_LINUX_VER)
    SED_CUR_ZFS_VER=$(sed_escape_input_string $CUR_ZFS_VER)

    # echo "CUR_ZFS_VER: $CUR_ZFS_VER"
    # echo "CUR_PKGREL_VER: $CUR_PKGREL_VER"
    # echo "CUR_LINUX_VER: $CUR_LINUX_VER"
    # echo "CUR_LINUX_PKGREL: $CUR_LINUX_PKGREL"
    # echo "SED_CUR_LIN_VER: $SED_CUR_LIN_VER"
    # echo "SED_CUR_ZFS_VER: $SED_CUR_ZFS_VER"

    # Change the top level PKGREL
    find . -iname "PKGBUILD" -print | xargs sed -i \
        "s/pkgrel=$CUR_PKGREL_VER/pkgrel=$PKGREL/g"

    # Replace the ZFS version
    find . -iname "PKGBUILD" -print | xargs sed -i \
        "s/$SED_CUR_ZFS_VER/$ZOL_VERSION/g"

    # Replace the linux version
    find . -iname "PKGBUILD" -print | xargs sed -i \
        "s/$SED_CUR_LIN_VER-$CUR_LINUX_PKGREL/$LINUX_VERSION-$LINUX_PKGREL/g"

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
