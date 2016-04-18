#!/bin/bash -e


#
# This script builds the archzfs packages in a clean clean chroot environment.
#
# clean-chroot-manager (https://github.com/graysky2/clean-chroot-manager) is required!
#


# Defaults, don't edit these.
AZB_UPDATE_PKGBUILDS=""
AZB_UPDPKGSUMS=0
AZB_UPDATE_TEST_PKGBUILDS=""
AZB_BUILD=0
AZB_USE_TEST=0
AZB_CHROOT_UPDATE=""
AZB_SIGN=""
AZB_CLEANUP=0
AZB_MODE_DEF=0
AZB_MODE_GIT=0
AZB_MODE_LTS=0


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${SCRIPT_DIR}/lib.sh; then
    echo "!! ERROR !! -- Could not lload lib.sh!"
fi


if ! source ${SCRIPT_DIR}/conf.sh; then
    error "Could not load conf.sh!"
fi


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
    echo "    -U:    Uses updpkgsums on PKGBUILDS."
    echo "    -C:    Remove all files that are not package sources."
    echo
    echo "Modes:"
    echo
    echo "    def    Use default packages."
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


build_def_sources() {
    for PKG in ${AZB_DEF_PKG_LIST}; do
        msg "Building source for $PKG";
        run_cmd "cd \"$PWD/packages/$PKG\""
        run_cmd "mkaurball -f"
        run_cmd "cd - > /dev/null"
    done
}


build_git_sources() {
    for PKG in ${AZB_GIT_PKG_LIST}; do
        msg "Building source for $PKG";
        run_cmd "cd \"$PWD/packages/$PKG\""
        run_cmd "mkaurball -f"
        run_cmd "cd - > /dev/null"
    done
}


build_lts_sources() {
    for PKG in ${AZB_LTS_PKG_LIST}; do
        msg "Building source for $PKG";
        run_cmd "cd \"$PWD/packages/$PKG\""
        run_cmd "mkaurball -f"
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
    full_kernel_git_version

    # Get SPL version
    cd spl-git
    check_git_repo
    [[ -d temp ]] && rm -r temp
    mkdir temp
    cd temp
    git clone ../spl
    cd spl
    git checkout -b azb $AZB_GIT_SPL_COMMIT
    AZB_NEW_SPL_X32_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^spl-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_GIT_KERNEL_X32_VERSION_CLEAN})
    AZB_NEW_SPL_X64_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^spl-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_GIT_KERNEL_X64_VERSION_CLEAN})
    cd ../../
    rm -rf temp
    cd ../

    # Get ZFS version
    cd zfs-git
    check_git_repo
    [[ -d temp ]] && rm -r temp
    mkdir temp
    cd temp
    git clone ../zfs
    cd zfs
    git checkout -b azb $AZB_GIT_ZFS_COMMIT
    AZB_NEW_ZFS_X32_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^zfs-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_GIT_KERNEL_X32_VERSION_CLEAN})
    AZB_NEW_ZFS_X64_PKGVER=$(echo $(git describe --long | \
        sed -r 's/^zfs-//;s/([^-]*-g)/r\1/;s/-/_/g')_${AZB_GIT_KERNEL_X64_VERSION_CLEAN})
    cd ../../
    rm -rf temp
    cd ../
}


check_git_repo() {
    # Checks the current path for a git repo
    [[ `cat PKGBUILD` =~ git\+([[:alpha:]\/:\.]+)\/([[:alpha:]]+)\.git  ]] &&
    local urlbase=${BASH_REMATCH[1]}; local reponame=${BASH_REMATCH[2]}
    local url=${urlbase}/${reponame}.git
    debug "BASH_REMATCH[1]: ${BASH_REMATCH[1]}"
    debug "BASH_REMATCH[2]: ${BASH_REMATCH[2]}"
    debug "GIT URL: $url"
    debug "GIT REPO: $reponame"
    if [[ ! -d "$reponame"  ]]; then
        msg2 "Cloning repo..."
        git clone --mirror "$url" "$reponame"
        if [[ $? != 0 ]]; then
            error "Failure while cloning $url repo"
            plain "Aborting..."
            exit 1
        fi
    else
        msg2 "Updating repo..."
        cd $reponame > /dev/null
        git fetch --all -p
        if [[ $? != 0 ]]; then
            error "Failure while fetching $url repo"
            plain "Aborting..."
            exit 1
        fi
        cd - > /dev/null
    fi

}


update_def_pkgbuilds() {
    # Calculate what the new pkgver would be for the git packages
    full_kernel_version ${AZB_DEF_KERNEL_VERSION} ${AZB_DEF_KERNEL_PKGREL_X32} ${AZB_DEF_KERNEL_PKGREL_X64}
    AZB_PKGVER=${AZB_ZOL_VERSION}_${AZB_KERNEL_VERSION_CLEAN_X64}
    debug "AZB_PKGVER: $AZB_PKGVER"
    # Replace the git commit id
    # $AZB_GIT_ZFS_COMMIT
    # $AZB_GIT_SPL_COMMIT
}


update_git_pkgbuilds() {
    # Calculate what the new pkgver would be for the git packages
    get_new_pkgver
    debug "AZB_NEW_SPL_PKGVER: $AZB_NEW_SPL_X64_PKGVER"
    debug "AZB_NEW_ZFS_PKGVER: $AZB_NEW_ZFS_X64_PKGVER"
    # Replace the git commit id
    # $AZB_GIT_ZFS_COMMIT
    # $AZB_GIT_SPL_COMMIT
}


update_lts_pkgbuilds() {
    # Set the AZB_LTS_KERNEL* variables
    full_kernel_version
    AZB_NEW_LTS_PKGVER=${AZB_ZOL_VERSION}_${AZB_LTS_KERNEL_X64_VERSION_CLEAN}
    debug "AZB_NEW_LTS_PKGVER: $AZB_NEW_LTS_PKGVER"
}


if [[ $# -lt 1 ]]; then
    usage;
    exit 0;
fi


ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "def" ]]; then
        AZB_MODE_DEF=1
    elif [[ ${ARGS[$a]} == "git" ]]; then
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
    elif [[ ${ARGS[$a]} == "-u" ]]; then
        AZB_CHROOT_UPDATE="-u"
    elif [[ ${ARGS[$a]} == "-U" ]]; then
        AZB_UPDPKGSUMS=1
    elif [[ ${ARGS[$a]} == "-C" ]]; then
        AZB_CLEANUP=1
    elif [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    fi
done


if [[ $AZB_CLEANUP -eq 1 && $# -gt 1 ]]; then
    echo -e "\n"
    error "-C should be used by itself!"
    echo -e "\n"
    usage;
    exit 0;
fi


if [[ ${AZB_MODE_DEF} -eq 0 && ${AZB_MODE_GIT} -eq 0 && ${AZB_MODE_LTS} -eq 0 && $AZB_CLEANUP -eq 0 ]]; then
    echo -e "\n"
    error "A build mode must be selected!"
    echo -e "\n"
    usage;
    exit 0;
fi


msg "$(date) :: build.sh started..."


if [[ $AZB_UPDPKGSUMS -eq 1 && ${AZB_MODE_LTS} -eq 1 ]]; then
    update_lts_pkgsums
fi


if [[ ${AZB_UPDATE_PKGBUILDS} -eq 1 && ${AZB_MODE_DEF} -eq 1 ]]; then
    msg "Updating default pkgbuilds"
    update_def_pkgbuilds
elif [[ ${AZB_UPDATE_PKGBUILDS} -eq 1 && ${AZB_MODE_GIT} -eq 1 ]]; then
    msg "Updating git pkgbuilds"
    update_git_pkgbuilds
elif [[ ${AZB_UPDATE_PKGBUILDS} -eq 1 && ${AZB_MODE_LTS} -eq 1 ]]; then
    msg "Updating lts pkgbuilds"
    update_lts_pkgbuilds
fi


if [ -n "$AZB_CHROOT_UPDATE" ]; then
    msg "Updating the i686 clean chroot..."
    run_cmd "sudo ccm32 u"
    msg "Updating the x86_64 clean chroot..."
    run_cmd "sudo ccm64 u"
fi


if [[ ${AZB_BUILD} -eq 1 && ${AZB_MODE_DEF} -eq 1 ]]; then
    for PKG in ${AZB_GIT_PKG_LIST}; do
        msg "Building $PKG..."
        run_cmd "cd \"$PWD/packages/$PKG\""
        run_cmd "sudo ccm32 s"
        run_cmd "sudo ccm64 s"
        run_cmd "cd - > /dev/null"
    done
    build_def_sources
    sign_packages
    run_cmd "find . -iname \"*.log\" -print -exec rm {} \\;"
elif [[ ${AZB_BUILD} -eq 1 && ${AZB_MODE_GIT} -eq 1 ]]; then
    for PKG in ${AZB_GIT_PKG_LIST}; do
        msg "Building $PKG..."
        run_cmd "cd \"$PWD/packages/$PKG\""
        run_cmd "sudo ccm32 s"
        run_cmd "sudo ccm64 s"
        run_cmd "cd - > /dev/null"
    done
    build_git_sources
    sign_packages
    run_cmd "find . -iname \"*.log\" -print -exec rm {} \\;"
elif [[ ${AZB_BUILD} -eq 1 && ${AZB_MODE_LTS} -eq 1 ]]; then
    for PKG in ${AZB_LTS_PKG_LIST}; do
        msg "Building $PKG..."
        run_cmd "cd \"$PWD/packages/$PKG\""
        run_cmd "sudo ccm32 s"
        run_cmd "sudo ccm64 s"
        run_cmd "cd - > /dev/null"
    done
    build_lts_sources
    sign_packages
    run_cmd "find . -iname \"*.log\" -print -exec rm {} \\;"
fi


if [[ $AZB_SIGN -eq 1 ]]; then
    sign_packages
fi


if [[ $AZB_CLEANUP -eq 1 ]]; then
    msg "Cleaning up work files..."
    run_cmd "find . \( -iname \"*.log\" -o -iname \"*.pkg.tar.xz*\" -o -iname \"*.src.tar.gz\" \) -print -exec rm -rf {} \\;"
    run_cmd "rm -rf  */src"
    run_cmd "rm -rf */*.tar.gz"
fi
