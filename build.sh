#!/bin/bash

PKGREL=1
ZFS_VER="0.6.1"
LINUX_VER="3.9.8"

PKG_LIST="spl-utils spl zfs-utils zfs"

GPG_SIGN_KEY='0EE7A126'
CHROOT_PATH="/opt/chroot"
REPO_BASE="/mnt/data/pacman/repo"
CHROOT_COPYNAME="azfs"

# Default variables, don't edit these.
BUILD=0
REPO=0
CLEANUP=0
UPDATE=""
UPDATE_PKGBUILDS=""
CLEAN=""
SIGN=""
CHROOT_TARGET=""
VERSION="${ZFS_VER}_${LINUX_VER}"
FULL_VERSION="$VERSION-$PKGREL"

set -e

shopt -s nullglob

# check if messages are to be printed using color
unset ALL_OFF BOLD BLUE GREEN RED YELLOW

# prefer terminal safe colored and bold text when tput is supported
if tput setaf 0 &>/dev/null; then
    ALL_OFF="$(tput sgr0)"
    BOLD="$(tput bold)"
    BLUE="${BOLD}$(tput setaf 4)"
    GREEN="${BOLD}$(tput setaf 2)"
    RED="${BOLD}$(tput setaf 1)"
    YELLOW="${BOLD}$(tput setaf 3)"
else
    ALL_OFF="\e[1;0m"
    BOLD="\e[1;1m"
    BLUE="${BOLD}\e[1;34m"
    GREEN="${BOLD}\e[1;32m"
    RED="${BOLD}\e[1;31m"
    YELLOW="${BOLD}\e[1;33m"
fi
readonly ALL_OFF BOLD BLUE GREEN RED YELLOW

plain() {
	local mesg=$1; shift
	printf "${BOLD}    ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg() {
	local mesg=$1; shift
	printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg2() {
	local mesg=$1; shift
	printf "${BLUE}  ->${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

warning() {
	local mesg=$1; shift
	printf "${YELLOW}==> $(gettext "WARNING:")${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

error() {
	local mesg=$1; shift
	printf "${RED}==> $(gettext "ERROR:")${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

usage() {
	echo "build.sh - A build script for archzfs"
    echo
	echo "Usage: $0 [options] [build chroot [options]] [repo name] [source]"
    echo
    echo "To update the PKGBUILDS"
    echo
    echo "  build.sh update"
    echo
    echo "To build in the the regular chroot (core) and perform update:"
    echo
    echo "  build.sh build core -u"
    echo
    echo "To build in the the test chroot (test):"
    echo
    echo "  build.sh build test"
    echo
    echo "To add the packages to demz-core-repo:"
    echo
    echo "  build.sh repo core"
    echo
    echo " To update and clean the chroot before building: "
    echo
    echo "  build.sh build core -u -c"
}

get_repo_name_from_shorthand() {
    # $1: The short form of the repo name
    if [[ $1 == "community" ]]; then
        echo "demz-repo-community"
    elif [[ $1 == "testing" ]]; then
        echo "demz-repo-testing"
    elif [[ $1 == "core" ]]; then
        echo "demz-repo-core"
    elif [[ $1 == "archiso" ]]; then
        echo "demz-repo-archiso"
    fi
}

sed_escape_input_string() {
    echo "$1" | sed -e 's/[]\/$*.^|[]/\\&/g'
}

build() {
    # $1: Directory containing packages
    # $2: List of dependencies to install
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
        FPKG=\$(find \"$REPO_BASE\" -type f \
                -regex ".*\$2/\$PKG.*\\(\$2\\|any\\).pkg.tar.xz")
        PLIST+="-I \$FPKG "
    done
    \$PLIST
}

CLEAN="$CLEAN"
UPDATE="$UPDATE"
for PKG in $PKG_LIST; do
    cd "$1/\$PKG"
    msg "Building \$PKG";
    pkgname=\$(grep "pkgname=" PKGBUILD | sed -e "s/pkgname=([\\'\\"]\\(.*\\)[\\'\\"])/\\1/")
    for ARCH in "i686" "x86_64"; do
        if [ -n "\$UPDATE" ]; then
            setarch \$ARCH arch-nspawn $CHROOT_PATH/\$ARCH/$CHROOT_TARGET/root pacman -Syu --noconfirm
        fi
        I_PKGS=\$(package_install_list "$2" \$ARCH)
        ARGS="\$CLEAN $I_PKGS -r $CHROOT_PATH/\$ARCH/$CHROOT_TARGET -l $CHROOT_COPYNAME"
        setarch \$ARCH makechrootpkg \$ARGS -- -i
    done
    # We only need to clean once, otherwise on the update all of the package
    # updates would be installed.
    CLEAN=
    UPDATE=
    cd - > /dev/null
done
EOF
    sudo bash $PWD/builder
    rm $PWD/builder
}

build_sources() {
    # $1: The directory containing the packages
    for PKG in $PKG_LIST; do
        cd "$1/$PKG"
        msg2 "Building source for $PKG";
        makepkg -Sfc
        cd - > /dev/null
    done
}

sign_packages() {
    # $1: The directory that contains the packages
    FILES=$(find $1 -iname "*${ZFS_VER}_${LINUX_VER}-${PKGREL}*.pkg.tar.xz")
    echo $FILES
    for F in $FILES; do
        msg2 "Signing $F"
        gpg --batch --yes --detach-sign --use-agent -u $GPG_SIGN_KEY "$F" # &>/dev/null
    done

}

cleanup() {
    find . \( -iname "*.log" -o -iname "sed*" \) -exec rm {} \;
}

add_to_repo() {
    # $1: The path to the package source
    for ARCH in 'i686' 'x86_64'; do
        REPO=`realpath $REPO_TARGET/$ARCH`
        [[ ! -d $REPO ]] && mkdir -p $REPO

        # Move the old packages to backup
        for X in $(find $REPO -type f -iname "*.pkg.tar.xz*"); do
            mv $X $REPO_BASE/backup/
        done

        # Copy the new packages
        for F in $(find $1 -type f -iname "*$FULL_VERSION-$ARCH.pkg.tar.xz*"); do
            cp $F $REPO/
        done

        repo-add -s -v -f $REPO/$REPO_NAME.db.tar.xz $REPO/*.pkg.tar.xz
    done
}

copy_sources() {
    # $1: The package source directory
    for F in $(find $1 -type f -iname "*${FULL_VERSION}.src.tar.gz"); do
        msg2 "Copying $F to $SOURCE_TARGET"
        [[ ! -d $SOURCE_TARGET ]] && mkdir -p $SOURCE_TARGET
        SEDPAT="s/(^[[:alpha:]\-]*)-${FULL_VERSION}\.src\.tar\.gz/\1/p"
        FNAME=$(echo $(basename $F) | sed -rn "$SEDPAT")
        # If there is zfs and zfs-utils in the directory, the glob will get
        # both zfs and zfs-utils when globbing zfs*, therefore we have to check
        # each file to see if it is the one we want.
        for T in "$(readlink -m $SOURCE_TARGET/$FNAME)"*.src.tar.gz; do
            ENAME=`echo $(basename $T) | sed -rn "s/(^[[:alpha:]\-]*)-.*\.src\.tar\.gz/\1/p"`
            if [[ $FNAME == $ENAME ]]; then
                rm -rf $T
            fi
        done
        cp $F $SOURCE_TARGET
    done
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

    # Replace the dependency versions of the archzfs packages
    find . -iname "PKGBUILD" -print | xargs sed -i \
        "s/_$SED_CUR_LIN_VER-$CUR_PKGREL_VER/_$LINUX_VER-$PKGREL/g"

    # Replace the PKGREL
    find . -iname "PKGBUILD" -print | xargs sed -i \
        "s/pkgrel=$CUR_PKGREL_VER/pkgrel=$PKGREL/g"

    # Replace the ZFS version
    find . -iname "PKGBUILD" -print | xargs sed -i "s/$SED_CUR_ZFS_VER/$ZFS_VER/g"

    # Replace the linux version
    find . -iname "PKGBUILD" -print | xargs sed -i "s/$SED_CUR_LIN_VER/$LINUX_VER/g"

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
    if [[ ${ARGS[$a]} == "build" ]]; then
        if [[ ${ARGS[`expr $a + 1`]} == "test" || ${ARGS[`expr $a + 1`]} == "core" ]]; then
            CHROOT_TARGET=${ARGS[`expr $a + 1`]}
        fi
        BUILD=1
    elif [[ ${ARGS[$a]} == "update" ]]; then
        UPDATE_PKGBUILDS=1
    elif [[ ${ARGS[$a]} == "sign" ]]; then
        SIGN=1
    elif [[ ${ARGS[$a]} == "repo" ]]; then
        REPO=1
        REPO_NAME=$(get_repo_name_from_shorthand ${ARGS[`expr $a + 1`]})
        REPO_TARGET=$REPO_BASE/$REPO_NAME
        SOURCE_TARGET="$REPO_TARGET/sources/"
    elif [[ ${ARGS[$a]} == "-u" ]]; then
        UPDATE="-u"
    elif [[ ${ARGS[$a]} == "-c" ]]; then
        CLEAN="-c"
    elif [[ ${ARGS[$a]} == "-C" ]]; then
        CLEANUP=1
    fi
done

if [[ $UPDATE_PKGBUILDS == 1 ]]; then
    update_pkgbuilds
fi

if [[ $SIGN == 1 ]]; then
    sign_packages .
fi


if [[ $BUILD == 1 ]]; then
    build .
    build_sources .
    sign_packages .
fi

if [[ $REPO == 1 ]]; then
    add_to_repo .
    copy_sources .
fi

if [[ $CLEANUP == 1 ]]; then
    msg2 "Cleaning up work files..."
    find . \( -iname "sed*" -o -iname "*.log" -o -iname "*.pkg.tar.xz*" \
        -o -iname "*.src.tar.gz" \) -print -exec rm -f {} \;
fi
