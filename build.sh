#!/bin/bash -e


#
# This script builds the archzfs packages in a clean clean chroot environment.
#
# clean-chroot-manager (https://github.com/graysky2/clean-chroot-manager) is required!
#


NAME=$(basename $0)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${SCRIPT_DIR}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
fi


if ! source ${SCRIPT_DIR}/conf.sh; then
    error "Could not load conf.sh!"
fi


if ! source ${SCRIPT_DIR}/src/HEADER.sh; then
    error "Could not load src/HEADER.sh!"
fi


trap 'trap_abort' INT QUIT TERM HUP
trap 'trap_exit' EXIT


# Defaults, don't edit these.
AZB_UPDATE_PKGBUILDS=""
AZB_UPDPKGSUMS=0
AZB_UPDATE_TEST_PKGBUILDS=""
AZB_BUILD=0
AZB_USE_TEST=0
AZB_CHROOT_UPDATE=""
AZB_SIGN=""
AZB_CLEANUP=0
AZB_COMMAND=""
AZB_MODE=""
AZB_MODE_STD=0
AZB_MODE_GIT=0
AZB_MODE_LTS=0


usage() {
    echo "${NAME} - A build script for archzfs"
    echo
    echo "Usage: ${NAME} [options] mode command [command ...]"
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
    echo "    std    Build the standard packages."
    echo "    git    Build the git packages."
    echo "    lts    Build the lts packages."
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
    echo "    ${NAME} -C                       :: Remove all compiled packages"
    echo "    ${NAME} git make -u              :: Update the chroot and build all of the packages"
    echo "    ${NAME} lts update               :: Update PKGBUILDS only"
    echo "    ${NAME} git update make -u       :: Update PKGBUILDs, update the chroot, and make all of the packages"
    echo "    ${NAME} lts update-test test -u  :: Update PKGBUILDs (use testing versions), update the chroot, and make all of the packages"
    trap - EXIT # Prevents exit log output
}


build_sources() {
    for PKG in ${AZB_PKG_LIST}; do
        msg "Building source for $PKG";
        run_cmd "cd \"$PWD/packages/${AZB_MODE}/$PKG\" && mkaurball -f"
    done
}


sign_packages() {
    FILES=$(find $PWD -iname "*.pkg.tar.xz")
    debug "Found FILES: ${FILES}"
    msg "Signing the packages with GPG"
    for F in $FILES; do
        if [[ ! -f "${F}.sig" ]]; then
            msg2 "Signing $F"
            run_cmd_no_output "gpg --batch --yes --detach-sign --use-agent -u $AZB_GPG_SIGN_KEY \"$F\""
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
    AZB_KERNEL_VERSION_FULL=$(full_kernel_version ${AZB_STD_KERNEL_VERSION})
    AZB_KERNEL_MOD_PATH="${AZB_KERNEL_VERSION_FULL}-ARCH"
    AZB_ARCHZFS_PACKAGE_GROUP="archzfs"
    AZB_PKGVER=${AZB_ZOL_VERSION}_$(full_kernel_version_no_hyphen ${AZB_STD_KERNEL_VERSION})
    AZB_PKGREL=${AZB_STD_PKGREL}
    AZB_SPL_UTILS_PKGNAME="spl-utils"
    AZB_SPL_PKGNAME="spl"
    AZB_ZFS_UTILS_PKGNAME="zfs-utils"
    AZB_ZFS_PKGNAME="zfs"
    AZB_SPL_UTILS_PKGBUILD_PATH="packages/${AZB_MODE}/spl-utils"
    AZB_SPL_PKGBUILD_PATH="packages/${AZB_MODE}/spl"
    AZB_ZFS_UTILS_PKGBUILD_PATH="packages/${AZB_MODE}/zfs-utils"
    AZB_ZFS_PKGBUILD_PATH="packages/${AZB_MODE}/zfs"

    debug "AZB_HEADER: ${AZB_HEADER}"
    debug "AZB_PKGVER: ${AZB_PKGVER}"
    debug "AZB_ZOL_VERSION: ${AZB_ZOL_VERSION}"
    debug "AZB_KERNEL_VERSION_FULL: ${AZB_KERNEL_VERSION_FULL}"
    debug "AZB_KERNEL_MOD_PATH: ${AZB_KERNEL_MOD_PATH}"
    debug "AZB_SPL_UTILS_PKGNAME: ${AZB_SPL_UTILS_PKGNAME}"
    debug "AZB_SPL_PKGNAME: ${AZB_SPL_PKGNAME}"
    debug "AZB_ZFS_UTILS_PKGNAME: ${AZB_ZFS_UTILS_PKGNAME}"
    debug "AZB_ZFS_PKGNAME: ${AZB_ZFS_PKGNAME}"
    debug "AZB_SPL_UTILS_PKGBUILD_PATH: ${AZB_SPL_UTILS_PKGBUILD_PATH}"
    debug "AZB_SPL_PKGBUILD_PATH: ${AZB_SPL_PKGBUILD_PATH}"
    debug "AZB_ZFS_UTILS_PKGBUILD_PATH: ${AZB_ZFS_UTILS_PKGBUILD_PATH}"
    debug "AZB_ZFS_PKGBUILD_PATH: ${AZB_ZFS_PKGBUILD_PATH}"
    debug "AZB_ZFS_SRC_HASH: ${AZB_ZFS_SRC_HASH}"
    debug "AZB_SPL_SRC_HASH: ${AZB_SPL_SRC_HASH}"
    debug "AZB_SPL_HOSTID_HASH: ${AZB_SPL_HOSTID_HASH}"
    debug "AZB_ZFS_BASH_COMPLETION_HASH: ${AZB_ZFS_BASH_COMPLETION_HASH}"
    debug "AZB_ZFS_INITCPIO_INSTALL_HASH: ${AZB_ZFS_INITCPIO_INSTALL_HASH}"
    debug "AZB_ZFS_INITCPIO_HOOK_HASH: ${AZB_ZFS_INITCPIO_HOOK_HASH}"
    debug "AZB_ARCHZFS_PACKAGE_GROUP: ${AZB_ARCHZFS_PACKAGE_GROUP}"

    # Finally, generate the update packages ...
    msg2 "Creating spl-utils PKGBUILD"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/spl-utils/PKGBUILD.sh"
    msg2 "Copying spl-utils.hostid"
    run_cmd_no_output "cp ${SCRIPT_DIR}/src/spl-utils/spl-utils.hostid ${AZB_SPL_UTILS_PKGBUILD_PATH}/spl-utils.hostid"

    msg2 "Creating spl PKGBUILD"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/spl/PKGBUILD.sh"
    msg2 "Creating spl.install"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/spl/spl.install.sh"

    msg2 "Creating zfs-utils PKGBUILD"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/zfs-utils/PKGBUILD.sh"
    msg2 "Copying zfs-utils.bash-completion"
    run_cmd_no_output "cp ${SCRIPT_DIR}/src/zfs-utils/zfs-utils.bash-completion-r1 ${AZB_ZFS_UTILS_PKGBUILD_PATH}/zfs-utils.bash-completion-r1"
    msg2 "Copying zfs-utils.initcpio.hook"
    run_cmd_no_output "cp ${SCRIPT_DIR}/src/zfs-utils/zfs-utils.initcpio.hook ${AZB_ZFS_UTILS_PKGBUILD_PATH}/zfs-utils.initcpio.hook"
    msg2 "Copying zfs-utils.initcpio.install"
    run_cmd_no_output "cp ${SCRIPT_DIR}/src/zfs-utils/zfs-utils.initcpio.install ${AZB_ZFS_UTILS_PKGBUILD_PATH}/zfs-utils.initcpio.install"

    msg2 "Creating zfs PKGBUILD"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/zfs/PKGBUILD.sh"
    msg2 "Creating zfs.install"
    run_cmd_no_output "source ${SCRIPT_DIR}/src/zfs/zfs.install.sh"
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


build_packages() {
    for PKG in ${AZB_PKG_LIST}; do
        msg "Building $PKG..."
        run_cmd "cd \"$PWD/packages/${AZB_MODE}/$PKG\" && sudo ccm64 s"
        msg2 "${PKG} package files:"
        run_cmd "tree ${AZB_CHROOT_PATH}/build/${PKG}/pkg"
    done
    build_sources
    sign_packages
    run_cmd "find . -iname \"*.log\" -print -exec rm {} \\;"
}


if [[ $# -lt 1 ]]; then
    usage;
    exit 0;
fi


ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "std" ]]; then
        AZB_MODE_STD=1
        AZB_MODE="std"
    elif [[ ${ARGS[$a]} == "git" ]]; then
        AZB_MODE_GIT=1
        AZB_MODE="git"
    elif [[ ${ARGS[$a]} == "lts" ]]; then
        AZB_MODE_LTS=1
        AZB_MODE="lts"
    elif [[ ${ARGS[$a]} == "make" ]]; then
        AZB_BUILD=1
        AZB_COMMAND="make"
    elif [[ ${ARGS[$a]} == "test" ]]; then
        AZB_USE_TEST=1
        AZB_COMMAND="test"
    elif [[ ${ARGS[$a]} == "update" ]]; then
        AZB_UPDATE_PKGBUILDS=1
        AZB_COMMAND="update"
    elif [[ ${ARGS[$a]} == "update-test" ]]; then
        AZB_UPDATE_TEST_PKGBUILDS=1
        AZB_COMMAND="update-test"
    elif [[ ${ARGS[$a]} == "sign" ]]; then
        AZB_SIGN=1
        AZB_COMMAND="sign"
    elif [[ ${ARGS[$a]} == "-u" ]]; then
        AZB_CHROOT_UPDATE="-u"
    elif [[ ${ARGS[$a]} == "-U" ]]; then
        AZB_UPDPKGSUMS=1
        AZB_COMMAND="update-pkgsums"
    elif [[ ${ARGS[$a]} == "-C" ]]; then
        AZB_CLEANUP=1
        AZB_COMMAND="clean"
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


if [[ ${AZB_MODE} == "" || ${AZB_COMMAND} == "" ]]; then
    echo
    error "A build mode and command must be selected!"
    echo
    usage;
    exit 0;
fi


msg "$(date) :: ${NAME} started..."


if [[ $AZB_UPDPKGSUMS -eq 1 && ${AZB_MODE_LTS} -eq 1 ]]; then
    update_lts_pkgsums
fi


if [ -n "$AZB_CHROOT_UPDATE" ]; then
    msg "Updating the x86_64 clean chroot..."
    run_cmd "sudo ccm64 u"
fi


AZB_PKG_LIST=""
if [[ ${AZB_UPDATE_PKGBUILDS} -eq 1 && ${AZB_MODE_STD} -eq 1 ]]; then
    msg "Updating default pkgbuilds"
    update_def_pkgbuilds
    if [[ ${AZB_BUILD} -eq 1 ]]; then
        AZB_PKG_LIST=${AZB_STD_PKG_LIST}
        build_packages
    fi
elif [[ ${AZB_UPDATE_PKGBUILDS} -eq 1 && ${AZB_MODE_GIT} -eq 1 ]]; then
    msg "Updating git pkgbuilds"
    update_git_pkgbuilds
    if [[ ${AZB_BUILD} -eq 1 ]]; then
        AZB_PKG_LIST=${AZB_GIT_PKG_LIST}
        build_packages
    fi
elif [[ ${AZB_UPDATE_PKGBUILDS} -eq 1 && ${AZB_MODE_LTS} -eq 1 ]]; then
    msg "Updating lts pkgbuilds"
    update_lts_pkgbuilds
    if [[ ${AZB_BUILD} -eq 1 ]]; then
        AZB_PKG_LIST=${AZB_LTS_PKG_LIST}
        build_packages
    fi
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
