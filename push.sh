#!/bin/bash


#
# push.sh is a script for pushing the archzfs package sources to AUR as well as
# the archzfs.com website
#


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${SCRIPT_DIR}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
fi


if ! source ${SCRIPT_DIR}/conf.sh; then
    error "Could not load conf.sh!"
fi


DRY_RUN=0       # Show commands only. Don't do anything.
DEBUG=0         # Show debug output.


AZB_MODE_DEF=0
AZB_MODE_GIT=0
AZB_MODE_LTS=0


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
    echo "    def       Use the default packages."
    echo "    git       Use the git packages."
    echo "    lts       Use the lts packages."
    echo
    echo "Example Usage:"
    echo
    echo "    push.sh   git     :: Push the git package sources."
    echo "    push.sh   lts     :: Push the lts package sources."
}


ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "def" ]]; then
        AZB_MODE_DEF=1
    elif [[ ${ARGS[$a]} == "git" ]]; then
        AZB_MODE_GIT=1
    elif [[ ${ARGS[$a]} == "lts" ]]; then
        AZB_MODE_LTS=1
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    elif [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    fi
done


if [[ $AZB_MODE_DEF == 0 && $AZB_MODE_GIT == 0 && $AZB_MODE_LTS == 0 ]]; then
    echo -e "\n"
    error "A mode must be selected!"
    echo -e "\n"
    usage;
    exit 0;
fi


FILES=""


if [[ $AZB_MODE_DEF == 1 ]]; then
    for PKG in $AZB_DEF_PKG_LIST; do
        full_kernel_git_version
        msg "Packaging $PKG..."
        run_cmd "cd \"$PWD/$PKG\""
        run_cmd "mksrcinfo"
        run_cmd "git add . && git commit -m 'Update for kernel $(full_kernel_version ${AZB_DEF_GIT_KERNEL_VERSION})'"
        run_cmd "git push"
        run_cmd "cd - > /dev/null"
    done
elif [[ $AZB_MODE_GIT == 1 ]]; then
    for PKG in $AZB_GIT_PKG_LIST; do
        full_kernel_git_version
        msg "Packaging $PKG..."
        run_cmd "cd \"$PWD/$PKG\""
        run_cmd "mksrcinfo"
        run_cmd "git add . && git commit -m 'Update for kernel $(full_kernel_version ${AZB_DEF_GIT_KERNEL_VERSION})'"
        run_cmd "git push"
        run_cmd "cd - > /dev/null"
    done
elif [[ $AZB_MODE_LTS == 1 ]]; then
    for PKG in $AZB_LTS_PKG_LIST; do
        full_kernel_lts_version
        msg "Packaging $PKG..."
        run_cmd "cd \"$PWD/$PKG\""
        run_cmd "mksrcinfo"
        run_cmd "git add . && git commit -m 'Update for kernel $AZB_LTS_KERNEL_X64_VERSION_FULL'"
        run_cmd "git push"
        run_cmd "cd - > /dev/null"
    done
fi


# Build the documentation and push it to the remote host
# msg "Building the documentation..."
# rst2html2 web_archzfs.rst > /tmp/archzfs_index.html
# msg2 "Pushing the documentation to the remote host..."
# scp /tmp/archzfs_index.html $REMOTE_LOGIN:webapps/default/archzfs/index.html
