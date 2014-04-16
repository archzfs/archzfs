#!/bin/bash
#
# This script builds the archzfs packages in a clean clean chroot environment.
#
# This script requires clean-chroot-manager (https://github.com/graysky2/clean-chroot-manager)
#
# Defaults, don't edit these.
AZB_GIT_PKG_LIST="spl-utils-git spl-git zfs-utils-git zfs-git"
AZB_UPDATE_PKGBUILDS=""
AZB_UPDATE_TEST_PKGBUILDS=""
AZB_BUILD=0
AZB_USE_TEST=0
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
	echo "Usage: build.sh [options] [command [command option] [...]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -n:    Dryrun; Output commands, but don't do anything."
    echo "    -d:    Show debug info."
    echo "    -u:    Perform an update in the clean chroot."
    echo "    -C:    Remove all files that are not package sources."
    echo
    echo "Commands:"
    echo
    echo "    make          Build all packages."
    echo "    test          Build test packages."
    echo "    update        Update all PKGBUILDs using conf.sh variables."
    echo "    update-test   Update all PKGBUILDs using the testing conf.sh variables."
    echo "    sign          GPG detach sign all compiled packages (default)."
    echo
	echo "Examples:"
    echo
    echo "    build.sh make -u              :: Update the chroot and build all of the packages"
    echo "    build.sh -C                   :: Remove all compiled packages"
    echo "    build.sh update               :: Update PKGBUILDS only"
    echo "    build.sh update make -u       :: Update PKGBUILDs, update the chroot, and make all of the packages"
    echo "    build.sh update-test test -u  :: Update PKGBUILDs (use testing versions), update the chroot, and make all of the packages"
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

full_kernel_version() {
    # Determine if the kernel version has the format 3.14 or 3.14.1
    [[ ${AZB_KERNEL_VERSION} =~ ^[[:digit:]]+\.[[:digit:]]+\.([[:digit:]]+) ]]
    if [[ ${BASH_REMATCH[1]} != "" ]]; then
        AZB_KERNEL_X32_VERSION_FULL=${AZB_KERNEL_X32_VERSION}
        AZB_KERNEL_X32_VERSION_CLEAN=$(echo ${AZB_KERNEL_X32_VERSION} | sed s/-/_/g)
        AZB_KERNEL_X64_VERSION_FULL=${AZB_KERNEL_X64_VERSION}
        AZB_KERNEL_X64_VERSION_CLEAN=$(echo ${AZB_KERNEL_X64_VERSION} | sed s/-/_/g)
    else
        # Kernel version has the format 3.14, so add a 0.
        AZB_KERNEL_X32_VERSION_FULL=${AZB_KERNEL_VERSION}.0-${AZB_KERNEL_X32_PKGREL}
        AZB_KERNEL_X32_VERSION_CLEAN=${AZB_KERNEL_VERSION}.0_${AZB_KERNEL_X32_PKGREL}
        AZB_KERNEL_X64_VERSION_FULL=${AZB_KERNEL_VERSION}.0-${AZB_KERNEL_X64_PKGREL}
        AZB_KERNEL_X64_VERSION_CLEAN=${AZB_KERNEL_VERSION}.0_${AZB_KERNEL_X64_PKGREL}
    fi
}

check_git_repo() {
    # Checks the current path for a git repo
    [[ `cat PKGBUILD` =~ git\+([[:alpha:]\/:\.]+)\/([[:alpha:]]+)\.git ]] && local \
        urlbase=${BASH_REMATCH[1]}; local reponame=${BASH_REMATCH[2]}
    local url=${urlbase}/${reponame}.git
    debug "BASH_REMATCH[1]: ${BASH_REMATCH[1]}"
    debug "BASH_REMATCH[2]: ${BASH_REMATCH[2]}"
    debug "GIT URL: $url"
    debug "GIT REPO: $reponame"
    if [[ ! -d "$reponame" ]]; then
        msg2 "Cloning repo..."
        if ! git clone --mirror "$url" "$reponame"; then
			error "Failure while cloning $url repo"
			plain "Aborting..."
            exit 1
        fi
    else
        msg2 "Updating repo..."
        if ! git fetch --all -p; then
			error "Failure while fetching $url repo"
			plain "Aborting..."
            exit 1
        fi
    fi
}

get_new_pkgver() {
    # Sets NEW_{SPL,ZFS}_PKGVER with an updated PKGVER pulled from the git repo

    full_kernel_version

    # Update the spl-utils-git repo
    cd spl-utils-git
    msg2 "Updating spl-utils-git repo..."
    check_git_repo
    cd spl
    AZB_NEW_SPL_X32_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^spl-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_KERNEL_X32_VERSION_CLEAN})
    AZB_NEW_SPL_X64_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^spl-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_KERNEL_X64_VERSION_CLEAN})
    cd ../../

    # Update the zfs-utils-git repo
    cd zfs-utils-git
    msg2 "Updating zfs-utils-git repo..."
    check_git_repo
    cd zfs
    AZB_NEW_ZFS_X32_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^zfs-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_KERNEL_X32_VERSION_CLEAN})
    AZB_NEW_ZFS_X64_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^zfs-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_KERNEL_X64_VERSION_CLEAN})
    cd ../../
}

update_git_pkgbuilds() {

    # Get variables from the existing PKGBUILDs
    AZB_CURRENT_SPL_PKGVER=$(grep "pkgver=" spl-git/PKGBUILD | cut -d= -f2)
    AZB_CURRENT_ZFS_PKGVER=$(grep "pkgver=" zfs-utils-git/PKGBUILD | cut -d= -f2)
    AZB_CURRENT_PKGREL=$(grep "pkgrel=" spl-git/PKGBUILD | cut -d= -f2)
    AZB_CURRENT_SPL_DEPVER=$(grep "spl=" zfs-git/PKGBUILD | cut -d\" -f2 | cut -d= -f2)
    AZB_CURRENT_X32_KERNEL_VERSION=$(grep -m1 "_kernel_version_x32=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X64_KERNEL_VERSION=$(grep -m1 "_kernel_version_x64=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X32_KERNEL_VERSION_CLEAN=$(grep -m1 "_kernel_version_x32_clean=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X64_KERNEL_VERSION_CLEAN=$(grep -m1 "_kernel_version_x64_clean=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X32_KERNEL_VERSION_FULL=$(grep -m1 "_kernel_version_x32_full=" spl-git/PKGBUILD | cut -d\" -f2)
    AZB_CURRENT_X64_KERNEL_VERSION_FULL=$(grep -m1 "_kernel_version_x64_full=" spl-git/PKGBUILD | cut -d\" -f2)

    # Calculate what the new pkgver would be for the git packages
    get_new_pkgver

    echo -e "\n\n"
    debug "AZB_NEW_SPL_PKGVER: $AZB_NEW_SPL_PKGVER"
    debug "AZB_NEW_ZFS_PKGVER: $AZB_NEW_ZFS_PKGVER"
    debug "AZB_CURRENT_SPL_PKGVER: $AZB_CURRENT_SPL_PKGVER"
    debug "AZB_CURRENT_ZFS_PKGVER: $AZB_CURRENT_ZFS_PKGVER"
    debug "AZB_CURRENT_PKGREL: $AZB_CURRENT_PKGREL"
    debug "AZB_CURRENT_SPL_DEPVER: $AZB_CURRENT_SPL_DEPVER"
    debug "AZB_CURRENT_X32_KERNEL_VERSION: $AZB_CURRENT_X32_KERNEL_VERSION"
    debug "AZB_CURRENT_X64_KERNEL_VERSION: $AZB_CURRENT_X64_KERNEL_VERSION"
    debug "AZB_CURRENT_X32_KERNEL_VERSION_CLEAN: $AZB_CURRENT_X32_KERNEL_VERSION_CLEAN"
    debug "AZB_CURRENT_X64_KERNEL_VERSION_CLEAN: $AZB_CURRENT_X64_KERNEL_VERSION_CLEAN"
    debug "AZB_CURRENT_X32_KERNEL_VERSION_FULL: $AZB_CURRENT_X32_KERNEL_VERSION_FULL"
    debug "AZB_CURRENT_X64_KERNEL_VERSION_FULL: $AZB_CURRENT_X64_KERNEL_VERSION_FULL"

    exit 1;

    # Change the top level AZB_PKGREL
    run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i \"s/pkgrel=$AZB_CURRENT_PKGREL/pkgrel=$AZB_PKGREL/g\""

    if [[ $AZB_UPDATE_PKGBUILDS ]]; then

        # Change the spl version number in zfs/PKGBUILD
        run_cmd "sed -i \"s/spl=$AZB_CURRENT_SPL_DEPVER/spl=$AZB_LINUX_FULL_VERSION/g\" zfs/PKGBUILD"

        # Change LINUX_VERSION_XXX
        run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i \
            \"s/_kernel_version_x32=\\\"$AZB_CURRENT_X32_KERNEL_VERSION\\\"/_kernel_version_x32=\\\"$AZB_LINUX_X32_VERSION\\\"/g\""
        run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i \
            \"s/_kernel_version_x64=\\\"$AZB_CURRENT_X64_KERNEL_VERSION\\\"/_kernel_version_x64=\\\"$AZB_LINUX_X64_VERSION\\\"/g\""

        # Replace the linux version in the top level PKGVER
        run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i
        \"s/pkgver=$AZB_CURRENT_SPL_PKGVER/pkgver=$AZB_LINUX_PKG_VERSION/g\""

    elif [[ $AZB_UPDATE_TEST_PKGBUILDS ]]; then

        # Change the spl version number in zfs/PKGBUILD
        run_cmd "sed -i \"s/spl=$AZB_CURRENT_SPL_DEPVER/spl=$AZB_LINUX_TEST_FULL_VERSION/g\" zfs/PKGBUILD"

        # Change LINUX_VERSION_XXX
        run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i \
            \"s/_kernel_version_x32=\\\"$AZB_CURRENT_X32_KERNEL_VERSION\\\"/_kernel_version_x32=\\\"$AZB_LINUX_TEST_X32_VERSION\\\"/g\""
        run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i \
            \"s/_kernel_version_x64=\\\"$AZB_CURRENT_X64_KERNEL_VERSION\\\"/_kernel_version_x64=\\\"$AZB_LINUX_TEST_X64_VERSION\\\"/g\""

        # Replace the linux version in the top level PKGVER
        run_cmd "find . -iname \"PKGBUILD\" -print | xargs sed -i
        \"s/pkgver=$AZB_CURRENT_SPL_PKGVER/pkgver=$AZB_LINUX_TEST_PKG_VERSION/g\""

    fi

    # Update the sums of the files
    for PKG in $AZB_GIT_PKG_LIST; do
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

msg "build.sh started..."

if [[ $AZB_UPDATE_PKGBUILDS == 1 || $AZB_UPDATE_TEST_PKGBUILDS == 1 ]]; then
    update_git_pkgbuilds
fi

if [[ $AZB_SIGN -eq 1 ]]; then
    sign_packages
fi

if [[ $AZB_BUILD_TEST == 1 ]]; then
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

if [[ $AZB_BUILD == 1 ]]; then
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

if [[ $AZB_CLEANUP -eq 1 ]]; then
    msg "Cleaning up work files..."
    run_cmd "find . \( -iname \"*.log\" -o -iname \"*.pkg.tar.xz*\" -o -iname \"*.src.tar.gz\" \) -print -exec rm -rf {} \\;"
fi
