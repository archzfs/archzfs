#!/bin/bash


#
# Makes sure the local archzfs repo matches what is live on archzfs.com
#


NAME=$(basename $0)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if ! source ${SCRIPT_DIR}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 1
fi
source_safe "${SCRIPT_DIR}/conf.sh"


# setup signal traps
trap 'clean_up' 0
for signal in TERM HUP QUIT; do
    trap "trap_exit $signal \"$(msg "$signal signal caught. Exiting...")\"" "$signal"
done
trap "trap_exit INT \"$(msg "Aborted by user! Exiting...")\"" INT
trap "trap_exit USR1 \"$(error "An unknown error has occurred. Exiting..." 2>&1 )\"" ERR


usage() {
    echo "${NAME} - Compares repository hashes."
    echo
    echo "Usage: ${NAME} [options]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -d:    Show debug info."
    echo
    echo "Examples:"
    echo
    echo "    ${NAME} -d    :: Show debug output."
    trap - EXIT # Prevents exit log output
}


ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    elif [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    fi
done


compute_local_repo_hash() {
    # $1: The repository to compute
    # Sets LOCAL_REPO_HASH
    msg2 "Computing local $1 repository hashes..."

    run_cmd "cd $REPO_BASEPATH; sha256sum $1/*/*"
    if [[ ${RUN_CMD_RETURN} != 0 ]]; then
        error "Could not run local hash!"
        exit 1
    fi

    LFILES=$(echo ${RUN_CMD_OUTPUT} | sort -r)

    LOCAL_REPO_HASH=$(echo "$LFILES" | sha256sum | cut -f 1 -d' ')
    msg2 "Local hash: $LOCAL_REPO_HASH"
}


compute_remote_repo_hash() {
    # $1: The repository to compute
    # Sets REMOTE_REPO_HASH
    msg2 "Computing remote $1 repository hashes..."

    run_cmd "ssh $REMOTE_LOGIN 'cd webapps/default; sha256sum $1/*/*'"
    if [[ ${RUN_CMD_RETURN} != 0 ]]; then
        error "Could not run remote hash!"
        exit 1
    fi

    RFILES=$(echo ${RUN_CMD_OUTPUT} | sort -r)

    REMOTE_REPO_HASH=$(echo "$RFILES" | sha256sum | cut -f 1 -d' ')
    msg2 "Remote hash: $REMOTE_REPO_HASH"
}


msg "$(date) :: ${NAME} started..."


# Bail if no internet
# Please thank Comcast for this requirement...
if [[ $(ping -w 1 -c 1 8.8.8.8 &> /dev/null; echo $?) != 0 ]]; then
    exit 0;
fi


HAS_ERROR=0


for REPO in 'archzfs'; do
    msg "Checking ${REPO}..."
    # compare_repo $REPO
    compute_local_repo_hash $REPO
    compute_remote_repo_hash $REPO
    if [[ $LOCAL_REPO_HASH != $REMOTE_REPO_HASH ]]; then
        error "The $REPO is out of sync!"
        HAS_ERROR=1
        continue
    fi
    msg2 "$REPO is in sync"
done


if [[ $HAS_ERROR -eq 1 ]]; then
    exit 1;
fi
