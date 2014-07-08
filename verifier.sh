#!/bin/bash

DIR="$( cd "$( dirname "$0"  )" && pwd  )"

set -e

source $DIR/lib.sh
source $DIR/conf.sh

trap 'trap_abort' INT QUIT TERM HUP
trap 'trap_exit' EXIT

usage() {
	echo "verifier.sh - Compares repository hashes."
    echo
	echo "Usage: ./verifier.sh [options]"
    echo
    echo "Options:"
    echo
    echo "    -h:    Show help information."
    echo "    -d:    Show debug info."
    echo
	echo "Examples:"
    echo
    echo "    verifier.sh -d    :: Show debug output."
}

ARGS=("$@")
for (( a = 0; a < $#; a++ )); do
    if [[ ${ARGS[$a]} == "-h" ]]; then
        usage;
        exit 0;
    elif [[ ${ARGS[$a]} == "-d" ]]; then
        DEBUG=1
    fi
done

compute_local_repo_hash() {
    # $1: The repository to compute
    # Sets LOCAL_REPO_HASH
    msg2 "Computing local $1 repository hashes..."
    LFILES=$(cd $AZB_REPO_BASEPATH; sha256sum $1/*/*)
    debug "Repository hash list:"
    debug "$LFILES"
    LOCAL_REPO_HASH=$(echo "$LFILES" | sha256sum | cut -f 1 -d' ')
    msg2 "Computed hash: $LOCAL_REPO_HASH"
}

compute_remote_repo_hash() {
    # $1: The repository to compute
    # Sets REMOTE_REPO_HASH
    msg2 "Computing remote $1 repository hashes..."
    RFILES=$(ssh $AZB_REMOTE_LOGIN "cd webapps/default; sha256sum $1/*/*")
    debug "Repository hash list:"
    debug "$RFILES"
    REMOTE_REPO_HASH=$(echo "$RFILES" | sha256sum | cut -f 1 -d' ')
    msg2 "Computed hash: $REMOTE_REPO_HASH"
}

compare_repo() {
    # $1: The repo name to compare
    compute_local_repo_hash $1
    compute_remote_repo_hash $1
    if [[ $REMOTE_REPO_HASH != $LOCAL_REPO_HASH ]]; then
        return 1
    fi
    return 0
}

for REPO in 'demz-repo-archiso' 'demz-repo-core'; do
    msg "Checking ${REPO}..."
    compare_repo $REPO
    if [[ $? != 0 ]]; then
        error "The database is out of sync, sending notification..."
        send_email "$REPO is out of sync!" "$REPO is not in sync!"
    fi
    msg2 "$REPO is in sync"
done
