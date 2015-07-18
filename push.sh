#!/bin/bash
#
# push.sh is a script for pushing the archzfs package sources to AUR as well as
# the archzfs package documentation.
#
source ./lib.sh
source ./conf.sh

DRY_RUN=0       # Show commands only. Don't do anything.
DEBUG=0         # Show debug output.
AZB_MODE_GIT=0
AZB_MODE_LTS=0
AZB_BUILD_AUR=0
AZB_BUILD_AUR4=0

usage() {
	echo "push.sh - Pushes the packages sources to AUR using burp."
    echo
	echo "Usage: push.sh [options] [mode]"
    echo
    echo "Options:"
    echo
    echo "    -h:       Show help information."
    echo "    -n:       Dryrun; Output commands, but don't do anything."
    echo "    -d:       Show debug info."
    echo
    echo "Modes:"
    echo
    echo "    git       Use the git packages."
    echo "    lts       Use the lts packages."
    echo "    aur       Save package sources to AUR4 directory."
    echo "    aur4      Save package sources to AUR4 directory."
    echo
    echo "Example Usage:"
    echo
    echo "    push.sh   git     :: Push the git package sources."
    echo "    push.sh   lts     :: Push the lts package sources."
}

ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "git" ]]; then
        AZB_MODE_GIT=1
    elif [[ ${ARGS[$a]} == "lts" ]]; then
        AZB_MODE_LTS=1
    elif [[ ${ARGS[$a]} == "aur" ]]; then
        AZB_BUILD_AUR=1
    elif [[ ${ARGS[$a]} == "aur4" ]]; then
        AZB_BUILD_AUR4=1
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    elif [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    fi
done

if [[ $AZB_MODE_GIT == 0 && $AZB_MODE_LTS == 0 ]]; then
    echo -e "\n"
    error "A mode must be selected!"
    echo -e "\n"
    usage;
    exit 0;
fi

FILES=""

if [[ $AZB_BUILD_AUR == 1 ]]; then
    msg "Pushing the package sources to AUR..."
    if [[ $AZB_MODE_GIT == 1 ]]; then
        full_kernel_git_version
        FILES=$(find $AZB_REPO_BASEPATH/demz-repo-core/x86_64/ -iname "*-git*${AZB_ZOL_VERSION}*${AZB_GIT_KERNEL_X64_VERSION_CLEAN}-${AZB_GIT_PKGREL}*.src.tar.gz" | tr "\n" " ")
        debug "${FILES}"
    elif [[ $AZB_MODE_LTS == 1 ]]; then
        full_kernel_lts_version
        FILES=$(find $AZB_REPO_BASEPATH/demz-repo-core/x86_64/ -iname "*-lts*${AZB_ZOL_VERSION}*${AZB_LTS_KERNEL_X64_VERSION_CLEAN}-${AZB_LTS_PKGREL}*.src.tar.gz" | tr "\n" " ")
        debug "${FILES}"
    fi
    run_cmd "burp -c modules ${FILES} -v"
fi

if [[ $AZB_BUILD_AUR4 == 1 && $AZB_MODE_GIT == 1 ]]; then
    for PKG in $AZB_GIT_PKG_LIST; do
        full_kernel_git_version
        msg "Packaging $PKG..."
        run_cmd "cd \"$PWD/$PKG\""
        run_cmd "mksrcinfo"
        run_cmd "git add . && git commit -m 'Update for kernel $AZB_GIT_KERNEL_X64_VERSION_FULL'; git push"
        run_cmd "cd - > /dev/null"
    done
elif [[ $AZB_BUILD_AUR4 == 1 && $AZB_MODE_LTS == 1 ]]; then
    for PKG in $AZB_LTS_PKG_LIST; do
        full_kernel_lts_version
        msg "Packaging $PKG..."
        run_cmd "cd \"$PWD/$PKG\""
        run_cmd "mksrcinfo"
        run_cmd "git add . && git commit -m 'Update for kernel $AZB_LTS_KERNEL_X64_VERSION_FULL' && git push"
        run_cmd "cd - > /dev/null"
    done
fi

# Build the documentation and push it to the remote host
# msg "Building the documentation..."
# rst2html2 web_archzfs.rst > /tmp/archzfs_index.html
# msg2 "Pushing the documentation to the remote host..."
# scp /tmp/archzfs_index.html $REMOTE_LOGIN:webapps/default/archzfs/index.html
