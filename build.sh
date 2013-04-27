#!/bin/bash

LINUX=3.8.8
PKGREL=2

# CLEAN="-c"
UPDATE="-u"

CHROOT_PATH="/opt/chroot"

CHROOT_BASE_NAME="archzfs"

REPO_PATH="/mnt/data/pacman/repo/demz-repo-core"

SOURCE_PATH="$REPO_PATH/sources"

GPG_SIGN_KEY='EE07A126'

set -e

function build_in_dir {
    cd $1
    for ARCH in 'i686' 'x86_64'; do
        ARGS="$UPDATE $CLEAN -r $CHROOT_PATH/$ARCH -l ${CHROOT_BASE_NAME}64"
        [[ $ARCH == "i686" ]] && ARGS="${ARGS:0:-2}32"
        sudo setarch $ARCH makechrootpkg $ARGS -- -i
        gpg --batch --yes --detach-sign $1*.pkg.tar.xz
    done
    makepkg -Sfc
    cd -
}

function add_packages_to_repo {
    for ARCH in 'i686' 'x86_64'; do
        REPO=$1/$ARCH/
        rm -rf $REPO/$2
        find . -type f -iname "$2-$ARCH.pkg.tar.xz*" -exec mv {} $REPO \;
        cd $REPO
        REPO_NAME=$(basename $1)
        FILES=$(find . -type f -iname "$2.pkg.tar.xz")
        repo-add -s -v -f $REPO_NAME.db.tar.xz $FILES
        cd -
    done
}

function move_package_sources {
    [[ ! -d $1 ]] && mkdir -p $1
    rm -rf "$1/*.src.tar.gz"
    find . -iname "*.src.tar.gz" -exec mv {} $1 \;
}

build_in_dir "spl-utils"
build_in_dir "spl"
build_in_dir "zfs-utils"
build_in_dir "zfs"

add_packages_to_repo "$REPO_PATH" "zfs*"
add_packages_to_repo "$REPO_PATH" "spl*"

move_package_sources "$SOURCE_PATH"
