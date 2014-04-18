#!/bin/bash
#
# This script builds the archzfs packages in a clean clean chroot environment.
#
# This script requires clean-chroot-manager (https://github.com/graysky2/clean-chroot-manager)
#
# Defaults, don't edit these.
AZB_GIT_PKG_LIST="spl-utils-git spl-git zfs-utils-git zfs-git"
AZB_LTS_PKG_LIST="spl-utils-lts spl-lts zfs-utils-lts zfs-lts"
AZB_UPDATE_PKGBUILDS=""
AZB_UPDATE_TEST_PKGBUILDS=""
AZB_BUILD=0
AZB_USE_TEST=0
AZB_CHROOT_UPDATE=""
AZB_SIGN=""
AZB_CLEANUP=0
AZB_MODE_GIT=0
AZB_MODE_LTS=0

source ./lib.sh
source ./conf.sh

set -e

trap 'trap_abort' INT QUIT TERM HUP
trap 'trap_exit' EXIT

usage() {
	echo "build.sh - A build script for archzfs"
    echo
	echo "Usage: build.sh [options] [mode] [command [command option] [...]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -n:    Dryrun; Output commands, but don't do anything."
    echo "    -d:    Show debug info."
    echo "    -u:    Perform an update in the clean chroot."
    echo "    -C:    Remove all files that are not package sources."
    echo
    echo "Modes:"
    echo
    echo "    git    Use the git packages."
    echo "    lts    Use the lts packages."
    echo
    echo "Commands:"
    echo
    echo "    make          Build all packages."
    echo "    test          Build test packages."
    echo "    update        Update all git PKGBUILDs using conf.sh variables."
    echo "    update-test   Update all git PKGBUILDs using the testing conf.sh variables."
    echo "    sign          GPG detach sign all compiled packages (default)."
    echo
	echo "Examples:"
    echo
    echo "    build.sh -C                       :: Remove all compiled packages"
    echo "    build.sh git make -u              :: Update the chroot and build all of the packages"
    echo "    build.sh lts update               :: Update PKGBUILDS only"
    echo "    build.sh git update make -u       :: Update PKGBUILDs, update the chroot, and make all of the packages"
    echo "    build.sh lts update-test test -u  :: Update PKGBUILDs (use testing versions), update the chroot, and make all of the packages"
}

sed_escape_input_string() {
    echo "$1" | sed -e 's/[]\/$*.^|[]/\\&/g'
}

build_sources() {
    for PKG in $AZB_GIT_PKG_LIST; do
        msg "Building source for $PKG";
        run_cmd "cd \"$PWD/$PKG\""
        run_cmd "makepkg -Sfc"
        run_cmd "cd - > /dev/null"
    done
}

sign_packages() {
    FILES=$(find $PWD -iname "*.pkg.tar.xz")
    debug "Found FILES: ${FILES}"
    msg "Signing the packages with GPG"
    for F in $FILES; do
        if [[ ! -f "${F}.sig" ]]; then
            msg2 "Signing $F"
            run_cmd "gpg --batch --yes --detach-sign --use-agent -u $AZB_GPG_SIGN_KEY \"$F\""
        fi
    done
}

get_new_pkgver() {
    # Sets NEW_{SPL,ZFS}_PKGVER with an updated PKGVER pulled from the git repo

    full_kernel_version

    # Get SPL version
    cd $AZB_SPL_GIT_PATH
    AZB_NEW_SPL_X32_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^spl-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_KERNEL_X32_VERSION_CLEAN})
    AZB_NEW_SPL_X64_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^spl-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_KERNEL_X64_VERSION_CLEAN})
    cd - > /dev/null

    # Get ZFS version
    cd $AZB_ZFS_GIT_PATH
    AZB_NEW_ZFS_X32_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^zfs-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_KERNEL_X32_VERSION_CLEAN})
    AZB_NEW_ZFS_X64_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^zfs-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_KERNEL_X64_VERSION_CLEAN})
    cd - > /dev/null
}

update_git_pkgbuilds() {

    # Get variables from the existing PKGBUILDs
    AZB_CURRENT_SPL_PKGVER=$(grep "pkgver=" spl-git/PKGBUILD | cut -d= -f2)
    AZB_CURRENT_SPL_UTILS_PKGVER=$(grep "pkgver=" spl-utils-git/PKGBUILD | cut -d= -f2)
    AZB_CURRENT_ZFS_PKGVER=$(grep "pkgver=" zfs-git/PKGBUILD | cut -d= -f2)
    AZB_CURRENT_ZFS_UTILS_PKGVER=$(grep "pkgver=" zfs-utils-git/PKGBUILD | cut -d= -f2)
    AZB_CURRENT_PKGREL=$(grep "pkgrel=" spl-git/PKGBUILD | cut -d= -f2)
    # AZB_CURRENT_SPL_DEPVER=$(grep "spl-git=" zfs-git/PKGBUILD | cut -d\" -f2 | cut -d= -f2)
    # AZB_CURRENT_ZFS_UTILS_DEPVER=$(grep "zfs-utils-git=" zfs-git/PKGBUILD | cut -d\" -f2 | cut -d= -f2)
    AZB_CURRENT_X32_KERNEL_VERSION=$(grep -m1 "_kernel_version_x32=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X64_KERNEL_VERSION=$(grep -m1 "_kernel_version_x64=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X32_KERNEL_VERSION_CLEAN=$(grep -m1 "_kernel_version_x32_clean=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X64_KERNEL_VERSION_CLEAN=$(grep -m1 "_kernel_version_x64_clean=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X32_KERNEL_VERSION_FULL=$(grep -m1 "_kernel_version_x32_full=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X64_KERNEL_VERSION_FULL=$(grep -m1 "_kernel_version_x64_full=" spl-git/PKGBUILD | cut -d\" -f2)

    # Calculate what the new pkgver would be for the git packages
    get_new_pkgver

    debug "AZB_NEW_SPL_PKGVER: $AZB_NEW_SPL_X64_PKGVER"
    debug "AZB_NEW_ZFS_PKGVER: $AZB_NEW_ZFS_X64_PKGVER"
    debug "AZB_CURRENT_SPL_PKGVER: $AZB_CURRENT_SPL_PKGVER"
    debug "AZB_CURRENT_SPL_UTILS_PKGVER: $AZB_CURRENT_SPL_UTILS_PKGVER"
    debug "AZB_CURRENT_ZFS_PKGVER: $AZB_CURRENT_ZFS_PKGVER"
    debug "AZB_CURRENT_ZFS_UTILS_PKGVER: $AZB_CURRENT_ZFS_UTILS_PKGVER"
    debug "AZB_CURRENT_PKGREL: $AZB_CURRENT_PKGREL"
    # debug "AZB_CURRENT_SPL_DEPVER: $AZB_CURRENT_SPL_DEPVER"
    # debug "AZB_CURRENT_ZFS_UTILS_DEPVER: $AZB_CURRENT_ZFS_UTILS_DEPVER"
    debug "AZB_CURRENT_X32_KERNEL_VERSION: $AZB_CURRENT_X32_KERNEL_VERSION"
    debug "AZB_CURRENT_X64_KERNEL_VERSION: $AZB_CURRENT_X64_KERNEL_VERSION"
    debug "AZB_CURRENT_X32_KERNEL_VERSION_CLEAN: $AZB_CURRENT_X32_KERNEL_VERSION_CLEAN"
    debug "AZB_CURRENT_X64_KERNEL_VERSION_CLEAN: $AZB_CURRENT_X64_KERNEL_VERSION_CLEAN"
    debug "AZB_CURRENT_X32_KERNEL_VERSION_FULL: $AZB_CURRENT_X32_KERNEL_VERSION_FULL"
    debug "AZB_CURRENT_X64_KERNEL_VERSION_FULL: $AZB_CURRENT_X64_KERNEL_VERSION_FULL"

    # Change the top level AZB_PKGREL
    run_cmd "find *-git -iname \"PKGBUILD\" -print | xargs sed -i \"s/pkgrel=$AZB_CURRENT_PKGREL/pkgrel=$AZB_PKGREL/g\""

    # Change _kernel_version_*
    run_cmd "find *-git -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/_kernel_version_x32=\\\"$AZB_CURRENT_X32_KERNEL_VERSION\\\"/_kernel_version_x32=\\\"$AZB_KERNEL_X32_VERSION\\\"/g\""
    run_cmd "find *-git -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/_kernel_version_x64=\\\"$AZB_CURRENT_X64_KERNEL_VERSION\\\"/_kernel_version_x64=\\\"$AZB_KERNEL_X64_VERSION\\\"/g\""

    run_cmd "find *-git -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/_kernel_version_x32_clean=\\\"$AZB_CURRENT_X32_KERNEL_VERSION_CLEAN\\\"/_kernel_version_x32_clean=\\\"$AZB_KERNEL_X32_VERSION_CLEAN\\\"/g\""
    run_cmd "find *-git -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/_kernel_version_x64_clean=\\\"$AZB_CURRENT_X64_KERNEL_VERSION_CLEAN\\\"/_kernel_version_x64_clean=\\\"$AZB_KERNEL_X64_VERSION_CLEAN\\\"/g\""

    run_cmd "find *-git -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/_kernel_version_x32_full=\\\"$AZB_CURRENT_X32_KERNEL_VERSION_FULL\\\"/_kernel_version_x32_full=\\\"$AZB_KERNEL_X32_VERSION_FULL\\\"/g\""
    run_cmd "find *-git -iname \"PKGBUILD\" -print | xargs sed -i \
        \"s/_kernel_version_x64_full=\\\"$AZB_CURRENT_X64_KERNEL_VERSION_FULL\\\"/_kernel_version_x64_full=\\\"$AZB_KERNEL_X64_VERSION_FULL\\\"/g\""

    # Replace the linux version in the top level PKGVER
    run_cmd "sed -i \"s/pkgver=$AZB_CURRENT_SPL_PKGVER/pkgver=$AZB_NEW_SPL_X64_PKGVER/g\" spl-git/PKGBUILD"
    run_cmd "sed -i \"s/pkgver=$AZB_CURRENT_SPL_UTILS_PKGVER/pkgver=$AZB_NEW_SPL_X64_PKGVER/g\" spl-utils-git/PKGBUILD"
    run_cmd "sed -i \"s/pkgver=$AZB_CURRENT_ZFS_PKGVER/pkgver=$AZB_NEW_ZFS_X64_PKGVER/g\" zfs-git/PKGBUILD"
    run_cmd "sed -i \"s/pkgver=$AZB_CURRENT_ZFS_UTILS_PKGVER/pkgver=$AZB_NEW_ZFS_X64_PKGVER/g\" zfs-utils-git/PKGBUILD"

    # Update the sums of the files
    for PKG in $AZB_GIT_PKG_LIST; do
        run_cmd "updpkgsums $PKG/PKGBUILD"
    done
}

update_git_test_pkgbuilds() {

    # elif [[ $AZB_UPDATE_TEST_PKGBUILDS ]]; then

        # # Change LINUX_VERSION_XXX
        # run_cmd "find ./*-git -iname \"PKGBUILD\" -print | xargs sed -i \
            # \"s/_kernel_version_x32=\\\"$AZB_CURRENT_X32_KERNEL_VERSION\\\"/_kernel_version_x32=\\\"$AZB_KERNEL_TEST_X32_VERSION\\\"/g\""
        # run_cmd "find ./*-git -iname \"PKGBUILD\" -print | xargs sed -i \
            # \"s/_kernel_version_x64=\\\"$AZB_CURRENT_X64_KERNEL_VERSION\\\"/_kernel_version_x64=\\\"$AZB_KERNEL_TEST_X64_VERSION\\\"/g\""

        # # Replace the linux version in the top level PKGVER
        # run_cmd "find ./*-git -iname \"PKGBUILD\" -print | xargs sed -i
        # \"s/pkgver=$AZB_CURRENT_SPL_PKGVER/pkgver=$AZB_KERNEL_TEST_PKG_VERSION/g\""
    return 0
}

update_lts_pkgbuilds() {
    return 0
}

if [[ $# -lt 1 ]]; then
    usage;
    exit 0;
fi

ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "git" ]]; then
        AZB_MODE_GIT=1
    elif [[ ${ARGS[$a]} == "lts" ]]; then
        AZB_MODE_LTS=1
    elif [[ ${ARGS[$a]} == "make" ]]; then
        AZB_BUILD=1
    elif [[ ${ARGS[$a]} == "test" ]]; then
        AZB_USE_TEST=1
    elif [[ ${ARGS[$a]} == "update" ]]; then
        AZB_UPDATE_PKGBUILDS=1
    elif [[ ${ARGS[$a]} == "update-test" ]]; then
        AZB_UPDATE_TEST_PKGBUILDS=1
    elif [[ ${ARGS[$a]} == "sign" ]]; then
        AZB_SIGN=1
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    elif [[ ${ARGS[$a]} == "-u" ]]; then
        AZB_CHROOT_UPDATE="-u"
    elif [[ ${ARGS[$a]} == "-C" ]]; then
        AZB_CLEANUP=1
    elif [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    fi
done

if [[ $AZB_CLEANUP == 1 && $# -gt 1 ]]; then
    echo -e "\n"
    error "-C should be used by itself!"
    echo -e "\n"
    usage;
    exit 0;
fi

if [[ $AZB_MODE_GIT == 0 && $AZB_MODE_LTS == 0 && $AZB_CLEANUP == 0 ]]; then
    echo -e "\n"
    error "A build mode must be selected!"
    echo -e "\n"
    usage;
    exit 0;
fi

msg "build.sh started..."

if [[ $AZB_UPDATE_PKGBUILDS == 1 && $AZB_MODE_GIT == 1 ]]; then
    update_git_pkgbuilds
fi

if [[ $AZB_BUILD_TEST == 1 && $AZB_MODE_GIT == 1 ]]; then
    if [ -n "$AZB_CHROOT_UPDATE" ]; then
        msg "Updating the i686 and x86_64 clean chroots..."
        run_cmd "sudo ccm32 u"
        run_cmd "sudo ccm64 u"
    fi
    for PKG in $AZB_GIT_PKG_LIST; do
        msg "Building $PKG..."
        run_cmd "cd \"$PWD/$PKG\""
        # run_cmd "sudo ccm32 t"
        run_cmd "sudo ccm32 s"
        # run_cmd "sudo ccm64 t"
        run_cmd "sudo ccm64 s"
        run_cmd "cd - > /dev/null"
    done
    build_sources
    sign_packages
fi

if [[ $AZB_BUILD == 1 && $AZB_MODE_GIT == 1 ]]; then
    if [ -n "$AZB_CHROOT_UPDATE" ]; then
        msg "Updating the i686 and x86_64 clean chroots..."
        run_cmd "sudo ccm32 u"
        run_cmd "sudo ccm64 u"
    fi
    for PKG in $AZB_GIT_PKG_LIST; do
        msg "Building $PKG..."
        run_cmd "cd \"$PWD/$PKG\""
        run_cmd "sudo ccm32 s"
        run_cmd "sudo ccm64 s"
        run_cmd "cd - > /dev/null"
    done
    build_sources
    sign_packages
fi

if [[ $AZB_SIGN -eq 1 ]]; then
    sign_packages
fi

if [[ $AZB_CLEANUP -eq 1 ]]; then
    msg "Cleaning up work files..."
    run_cmd "find . \( -iname \"*.log\" -o -iname \"*.pkg.tar.xz*\" -o -iname \"*.src.tar.gz\" \) -print -exec rm -rf {} \\;"
fi
