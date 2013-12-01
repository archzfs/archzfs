#!/bin/bash

#
# repo.sh adds the archzfs packages to a specified repository.
#

source "lib.sh"
source "conf.sh"

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

usage() {
	echo "repo.sh - Adds the archzfs packages to the $REPO_TARGET repository"
    echo
	echo "Usage: $0 <repo> [version]"
    echo
    echo "  $0 core ::"
    echo "      Adds the latest archzfs packages ($PKG_VERSION) to the "
    echo "      $(get_repo_name_from_shorthand "core") repository."
}

if [ $# -lt 1 ]; then
    usage;
    exit 0;
fi

REPO_NAME=$(get_repo_name_from_shorthand $1)
REPO_TARGET=$REPO_BASEPATH/$REPO_NAME
SOURCE_TARGET="$REPO_TARGET/sources/"

if [[ $REPO_NAME == "demz-repo-archiso" ]]; then
    export FULL_VERSION=$ARCHISO_FULL_VERSION
fi

add_to_repo() {
    # $1: The path to the package source
    for ARCH in 'i686' 'x86_64'; do
        REPO=`realpath $REPO_TARGET/$ARCH`
        [[ ! -d $REPO ]] && mkdir -p $REPO

        # Move the old packages to backup
        for X in $(find $REPO -type f -iname "*.pkg.tar.xz*"); do
            mv $X $REPO_BASEPATH/backup/
        done

        # Copy the new packages
        for F in $(find . -type f -iname "*${FULL_VERSION}-$ARCH.pkg.tar.xz*"); do
            cp $F $REPO/
        done

        repo-add -s -v -f $REPO/${REPO_NAME}.db.tar.xz $REPO/*.pkg.tar.xz
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

add_to_repo
copy_sources
