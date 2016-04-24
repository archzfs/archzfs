#!/bin/bash -e


#
# push.sh is a script for pushing the archzfs package sources to AUR as well as
# the archzfs.com website
#


NAME=$(basename $0)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${SCRIPT_DIR}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 1
fi
source_safe "${SCRIPT_DIR}/conf.sh"


# setup signal traps
trap "trap_quit" TERM HUP QUIT
trap "trap_abort" INT
trap "trap_usr1" USR1
trap "trap_exit" EXIT


DRY_RUN=0       # Show commands only. Don't do anything.
DEBUG=0         # Show debug output.
MODE=""
MODE_NAME=""
MODE_LIST=()


usage() {
    echo "${NAME} - Pushes the packages sources to AUR using burp."
    echo
    echo "Usage: ${NAME} [options] [mode]"
    echo
    echo "Options:"
    echo
    echo "    -h:       Show help information."
    echo "    -n:       Dryrun; Output commands, but don't do anything."
    echo "    -d:       Show debug info."
    echo
    echo "Modes:"
    echo
    for mode in "${MODE_LIST[@]}"; do
        mode_name=$(echo ${mode} | cut -f2 -d:)
        mode_desc=$(echo ${mode} | cut -f3 -d:)
        echo -e "    ${mode_name}    ${mode_desc}"
    done
    echo
    echo "Example Usage:"
    echo
    echo "    ${NAME} git     :: Push the git package sources."
    echo "    ${NAME} lts     :: Push the lts package sources."
    trap - EXIT # Prevents exit log output
}


ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "-n" ]]; then
        DRY_RUN=1
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    else
        check_mode
    fi
done


if [[ $# -lt 1 ]]; then
    usage;
    exit 0;
fi


if [[ ${MODE} == "" ]]; then
    echo
    error "A mode must be selected!"
    usage;
    exit 0;
fi


msg "$(date) :: ${NAME} started..."


push_packages() {
    for pkg in ${pkg_list}; do
        msg "Packaging ${pkg}..."
        local cmd="cd \"${PWD}/packages/${MODE_NAME}/${pkg}\" && "
        cmd+="mksrcinfo && "
        cmd+="git add . && git commit -m 'Update for kernel $(kernel_version_full ${kernel_version})' && "
        cmd+="git push"
        run_cmd "${cmd}"
    done
}


if [[ ${MODE} != "" ]]; then
    get_kernel_update_funcs
    export SCRIPT_DIR MODE MODE_NAME BUILD SIGN SOURCES UPDATE_PKGBUILDS
    source_safe "src/kernels/${MODE_NAME}.sh"
    for func in "${UPDATE_FUNCS[@]}"; do
        debug "Evaluating '${func}'"
        "${func}"
        push_packages
    done
fi


# Build the documentation and push it to the remote host
# msg "Building the documentation..."
# rst2html2 web_archzfs.rst > /tmp/archzfs_index.html
# msg2 "Pushing the documentation to the remote host..."
# scp /tmp/archzfs_index.html $REMOTE_LOGIN:webapps/default/archzfs/index.html
